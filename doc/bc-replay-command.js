async function userPasswordAuthenticate(page, url, username, password) {
    try {
        console.log('开始登录流程...');
        
        // 等待页面加载完成
        await page.waitForLoadState('networkidle', { timeout: 30000 });
        console.log('页面加载完成');
        
        // 调试信息：输出当前URL
        console.log('当前页面URL:', page.url());
        
        // 等待并确保用户名输入框可见和可交互
        console.log('等待用户名输入框...');
        await page.waitForSelector('input[name=UserName]', { 
            state: 'visible',
            timeout: 30000 
        });
        console.log('找到用户名输入框');
        
        // 输出页面上所有输入框的信息
        const inputs = await page.$$eval('input', inputs => 
            inputs.map(input => ({
                type: input.type,
                name: input.name,
                id: input.id,
                visible: input.offsetParent !== null
            }))
        );
        console.log('页面上的输入框:', inputs);

        // 清除输入框并填写用户名
        await page.waitForSelector('input[name=UserName]', { 
            state: 'visible',
            timeout: 30000 
        });
        
        await page.fill('input[name=UserName]', username);

        // 等待密码输入框
        await page.waitForSelector('input[name=Password]', { 
            state: 'visible',
            timeout: 30000 
        });
        
        await page.fill('input[name=Password]', password);

        // 等待提交按钮并点击
        await page.waitForSelector('button[type=submit]', {
            state: 'visible',
            timeout: 30000
        });
        
        // 使用 Promise.all 确保等待导航完成
        await Promise.all([
            page.waitForNavigation({ 
                timeout: 60000,
                waitUntil: 'networkidle' 
            }),
            page.click('button[type=submit]')
        ]);

        // 等待页面完全加载
        await page.waitForLoadState('networkidle', { timeout: 30000 });
        
    } catch (error) {
        console.error('登录过程出错:', error);
        
        // 获取更多调试信息
        try {
            const screenshot = await page.screenshot({ 
                path: 'login-error.png',
                fullPage: true 
            });
            console.log('错误截图已保存为 login-error.png');
            
            // 输出更详细的页面信息
            const content = await page.content();
            console.log('页面HTML内容:', content);
            
            // 输出所有可见元素
            const visibleElements = await page.$$eval('*', elements =>
                elements.filter(el => el.offsetParent !== null)
                    .map(el => ({
                        tag: el.tagName,
                        id: el.id,
                        class: el.className,
                        text: el.innerText
                    }))
            );
            console.log('可见元素:', visibleElements);
            
        } catch (e) {
            console.error('无法获取调试信息:', e);
        }
        
        throw error;
    }
}




























try {
        console.log('开始登录流程...');
        
        // 处理 HTTP Basic Authentication
        // 方法1：在 URL 中直接包含认证信息
        const urlObj = new URL(url);
        const authenticatedUrl = `${urlObj.protocol}//${username}:${password}@${urlObj.host}${urlObj.pathname}${urlObj.search}`;
        await page.goto(authenticatedUrl);

        // 方法2：使用 authenticate 方法
        await page.authenticate({
            username: username,
            password: password
        });

        // 等待页面加载完成
        await page.waitForLoadState('networkidle', { timeout: 30000 });
        console.log('页面加载完成');

        // 验证是否登录成功
        const currentUrl = page.url();
        console.log('当前页面URL:', currentUrl);
        
        if (currentUrl.includes('login') || currentUrl.includes('auth')) {
            throw new Error('登录可能未成功，当前URL包含登录相关路径');
        }

    } catch (error) {
        console.error('登录过程出错:', error);
        
        // 获取更多调试信息
        try {
            const screenshot = await page.screenshot({ 
                path: 'login-error.png',
                fullPage: true 
            });
            console.log('错误截图已保存为 login-error.png');
            
            // 由于是 HTTP 认证，无法获取 HTML 内容
            console.log('当前URL:', page.url());
            
        } catch (e) {
            console.error('无法获取调试信息:', e);
        }
        
        throw error;
    }
}

// 在 userPasswordAuthenticate 函数开始时添加
page.on('dialog', async dialog => {
    console.log('检测到对话框:', {
        type: dialog.type(),
        message: dialog.message()
    });
    await dialog.accept(); // 或 dialog.dismiss() 取决于需要
});

page.on('request', request => {
    console.log('请求:', {
        url: request.url(),
        headers: request.headers(),
        method: request.method()
    });
});

page.on('response', response => {
    console.log('响应:', {
        url: response.url(),
        status: response.status(),
        headers: response.headers()
    });
});








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

try {
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

    # 执行测试
    Write-Log "开始执行测试..."
    Write-Log "录制文件: $recordingPath"
    Write-Log "目标地址: $startAddr"
    Write-Log "结果目录: $resultDirectory"
    Write-Log "认证方式: $($config.authentication)"

    # 捕获详细输出
    $output = & npx replay $replayArgs 2>&1 | Tee-Object -Variable cmdOutput
    
    # 将输出写入日志文件
    $logFile = Join-Path $resultDirectory "test-execution.log"
    $cmdOutput | Out-File -FilePath $logFile -Encoding UTF8

    # 检查执行结果
    if ($LASTEXITCODE -eq 0) {
        Write-Log "测试执行成功完成" "SUCCESS"
        Write-Log "详细日志已保存到: $logFile" "INFO"
        
        # 如果结果目录中有测试报告，将其位置输出到控制台
        $reportFile = Join-Path $resultDirectory "report.html"
        if (Test-Path $reportFile) {
            Write-Log "测试报告位置: $reportFile" "INFO"
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



steps:
- task: PowerShell@2
  inputs:
    targetType: 'filePath'
    filePath: 'run-bc-replay.ps1'
    arguments: '-Recording ".\recordings\*.yml" -StartAddress "http://localhost:8080/bc250/" -ResultDir "c:\bc-replay\result"'
    failOnStderr: true
  displayName: '运行 BC-Replay 测试'

# 如果需要发布测试结果和日志
- task: PublishPipelineArtifact@1
  inputs:
    targetPath: 'c:\bc-replay\result'
    artifact: 'TestResults'
    publishLocation: 'pipeline'
  condition: always()




主要改进包括：
使用 Tee-Object 同时捕获并显示输出
将详细日志保存到文件
使用 Write-Host "##vso[task.complete result=Failed;]$_" 确保错误正确地反馈给 Azure Pipeline
添加了测试报告位置的输出
使用 PublishPipelineArtifact 任务保存测试结果
这样配置后，你可以：
在 Pipeline 运行日志中实时查看执行过程
在运行失败时看到详细的错误信息
在 Pipeline 构建结果中下载完整的测试结果和日志
通过 Pipeline 的 Artifacts 查看测试报告和详细日志
如果测试失败，错误信息会：
显示在 Pipeline 日志中
保存在结果目录的 test-execution.log 文件中
导致 Pipeline 任务失败并显示错误信息





