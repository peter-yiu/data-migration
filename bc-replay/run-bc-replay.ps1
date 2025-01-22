#!/usr/bin/env pwsh

<#
.SYNOPSIS
运行 BC-Replay 测试的便捷脚本。

.DESCRIPTION
此脚本用于简化 BC-Replay 测试的执行过程，支持配置文件和命令行参数。

.PARAMETER ConfigFile
(可选) 配置文件的路径，默认为 "./bc-replay.config.json"

.PARAMETER Recording
(可选) 指定要运行的录制文件，如果不指定则运行配置文件中定义的所有录制文件

.PARAMETER StartAddress
(可选) 覆盖配置文件中的 startAddress

.PARAMETER ResultDir
(可选) 覆盖配置文件中的 resultDir

.PARAMETER Username
(可选) Business Central 用户名

.PARAMETER Password
(可选) Business Central 密码
#>

param (
    [Parameter()]
    [string]
    $ConfigFile = "./bc-replay.config.json",

    [Parameter()]
    [string]
    $Recording,

    [Parameter()]
    [string]
    $StartAddress,

    [Parameter()]
    [string]
    $ResultDir,

    [Parameter()]
    [string]
    $Username,

    [Parameter()]
    [string]
    $Password
)

# 错误处理
$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Level - $Message"
}

# 定义共享文件夹路径和报告存储结构
$shareFolder = "\\your-server\share\test-reports"
$dateFolder = (Get-Date).ToString("yyyy-MM-dd")
$buildFolder = if ($env:BUILD_BUILDNUMBER) { $env:BUILD_BUILDNUMBER } else { "local-$(Get-Date -Format 'HHmmss')" }
$targetFolder = Join-Path $shareFolder $dateFolder $buildFolder

try {
    # 检查 Node.js 环境
    Write-Log "检查 Node.js 环境..."
    $nodeVersion = node --version
    if ($LASTEXITCODE -ne 0) {
        throw "未找到 Node.js，请确保已安装 Node.js"
    }
    Write-Log "Node.js 版本: $nodeVersion"

    # 检查 npm 环境
    $npmVersion = npm --version
    if ($LASTEXITCODE -ne 0) {
        throw "未找到 npm，请确保已安装 npm"
    }
    Write-Log "npm 版本: $npmVersion"

    # 确保已安装必要的 npm 包
    Write-Log "检查并安装必要的 npm 包..."
    if (!(Test-Path "node_modules")) {
        Write-Log "正在安装依赖包..."
        npm install
        if ($LASTEXITCODE -ne 0) {
            throw "npm 包安装失败"
        }
    }

    # 读取配置文件
    if (!(Test-Path $ConfigFile)) {
        throw "配置文件 '$ConfigFile' 不存在"
    }
    
    $config = Get-Content $ConfigFile | ConvertFrom-Json

    # 设置参数，命令行参数优先级高于配置文件
    $recordingPath = if ($Recording) { $Recording } else { $config.recordings }
    $startAddr = if ($StartAddress) { $StartAddress } else { $config.startAddress }
    $resultDirectory = if ($ResultDir) { $ResultDir } else { $config.resultDir }

    # 设置认证环境变量
    if ($Username) {
        $env:$config.userNameKey = $Username
    }
    if ($Password) {
        $env:$config.passwordKey = $Password
    }

    # 验证认证信息
    if ($config.authentication -eq "UserPassword") {
        if (!(Get-Item env:$($config.userNameKey) -ErrorAction Ignore)) {
            throw "未设置用户名环境变量。请使用 -Username 参数或设置 $($config.userNameKey) 环境变量"
        }
        if (!(Get-Item env:$($config.passwordKey) -ErrorAction Ignore)) {
            throw "未设置密码环境变量。请使用 -Password 参数或设置 $($config.passwordKey) 环境变量"
        }
    }

    # 确保结果目录存在
    if (!(Test-Path $resultDirectory)) {
        New-Item -ItemType Directory -Path $resultDirectory -Force | Out-Null
        Write-Log "创建结果目录: $resultDirectory"
    }

    # 构建命令参数
    $replayArgs = @(
        $recordingPath,
        "-StartAddress", $startAddr,
        "-ResultDir", $resultDirectory,
        "-Authentication", $config.authentication,
        "-UserNameKey", $config.userNameKey,
        "-PasswordKey", $config.passwordKey
    )

    # 添加可选参数
    if ($config.timeout) {
        $replayArgs += "-Timeout"
        $replayArgs += $config.timeout
    }
    if ($config.maxRetries) {
        $replayArgs += "-MaxRetries"
        $replayArgs += $config.maxRetries
    }
    if ($config.retryDelay) {
        $replayArgs += "-RetryDelay"
        $replayArgs += $config.retryDelay
    }

    # 执行测试（使用完整路径）
    $npxPath = Join-Path (Get-Location) "node_modules\.bin\replay"
    if (!(Test-Path $npxPath)) {
        $npxPath = "npx replay"  # 回退到使用 npx
    }

    Write-Log "开始执行测试..."
    Write-Log "使用命令: $npxPath"
    Write-Log "录制文件: $recordingPath"
    Write-Log "目标地址: $startAddr"
    Write-Log "结果目录: $resultDirectory"
    Write-Log "认证方式: $($config.authentication)"

    # 捕获详细输出
    $output = & $npxPath $replayArgs 2>&1 | Tee-Object -Variable cmdOutput
    
    # 将输出写入日志文件
    $logFile = Join-Path $resultDirectory "test-execution.log"
    $cmdOutput | Out-File -FilePath $logFile -Encoding UTF8

    # 检查执行结果
    if ($LASTEXITCODE -eq 0) {
        Write-Log "测试执行成功完成" "SUCCESS"
        
        # 复制报告到共享文件夹
        try {
            # 确保目标文件夹存在
            if (!(Test-Path $targetFolder)) {
                New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
            }

            # 复制所有测试结果和报告
            Write-Log "正在复制测试报告到共享文件夹: $targetFolder"
            Copy-Item -Path "$resultDirectory\*" -Destination $targetFolder -Recurse -Force

            # 创建一个简单的索引页面
            $indexContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>测试报告 - $buildFolder</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .info { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>测试报告</h1>
    <div class="info">
        <p>构建编号: $buildFolder</p>
        <p>执行时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <p><a href="report.html">查看详细报告</a></p>
</body>
</html>
"@
            $indexContent | Out-File -FilePath (Join-Path $targetFolder "index.html") -Encoding UTF8

            Write-Log "报告已复制到: $targetFolder" "SUCCESS"
            
            # 如果在本地环境，自动打开报告
            if (-not $env:BUILD_BUILDID) {
                Start-Process (Join-Path $targetFolder "index.html")
            }
        }
        catch {
            Write-Log "复制报告到共享文件夹时出错: $_" "WARNING"
            Write-Log "将继续执行，但报告可能未完全复制" "WARNING"
        }
    } else {
        Write-Log "测试执行失败，退出码: $LASTEXITCODE" "ERROR"
        Write-Log "错误详情：`n$cmdOutput" "ERROR"
        throw "测试执行失败，详细信息请查看日志文件: $logFile"
    }
}
catch {
    Write-Log "执行出错: $_" "ERROR"
    Write-Log "堆栈跟踪: $($_.ScriptStackTrace)" "DEBUG"
    
    # 确保错误信息被正确传递给 Azure Pipeline
    Write-Host "##vso[task.complete result=Failed;]$_"
    exit 1
} 