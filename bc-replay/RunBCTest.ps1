# 设置 BC 服务器连接参数
$bcServerUrl = "http://your-bc-server:7048/BC250/ODataV4"  # BC服务器URL
$bcCompany = "CRONUS"  # 公司名称
$credential = Get-Credential -Message "请输入BC凭据"  # 获取用户凭据

# 运行录制的脚本
function Invoke-RecordedScript {
    param (
        [string]$ScriptPath
    )
    
    try {
        # 创建 BC 连接
        $bcConnection = New-Object Microsoft.Dynamics.Nav.Types.WebServiceConnection
        $bcConnection.ServerUrl = $bcServerUrl
        $bcConnection.Credential = $credential
        $bcConnection.Company = $bcCompany
        
        # 读取并执行录制的脚本
        $recordedScript = Get-Content $ScriptPath -Raw
        
        # 创建脚本上下文
        $scriptBlock = [ScriptBlock]::Create($recordedScript)
        
        # 执行脚本
        $result = Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $bcConnection
        
        if ($result) {
            Write-Host "录制脚本执行成功!" -ForegroundColor Green
        } else {
            Write-Host "录制脚本执行失败!" -ForegroundColor Red
        }
    }
    catch {
        Write-Error "执行录制脚本时发生错误: $_"
    }
}

# 运行录制的脚本
$recordedScriptPath = "C:\BCScripts\RecordedTest.ps1"
Invoke-RecordedScript -ScriptPath $recordedScriptPath 