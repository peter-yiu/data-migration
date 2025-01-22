# 设置 BC 服务器连接参数
$bcServerUrl = "http://your-bc-server:7048/BC250"  # 修改为你的BC服务器地址
$bcCompany = "CRONUS"
$webClientUrl = "$bcServerUrl/WebClient?company=$bcCompany"

# 获取凭据
$credential = Get-Credential -UserName "admin" -Message "请输入BC管理员密码"

# 导入必要的程序集
Add-Type -Path "C:\Program Files\Microsoft Dynamics 365 Business Central\250\Service\Microsoft.Dynamics.Framework.UI.Client.dll"

# 运行录制的脚本
function Invoke-RecordedScript {
    param (
        [string]$ScriptPath
    )
    
    try {
        # 创建客户端会话
        $clientSession = New-Object Microsoft.Dynamics.Framework.UI.Client.ClientSession
        $clientSession.OpenSession($webClientUrl, $credential)
        
        Write-Host "已成功连接到BC" -ForegroundColor Green
        
        # 读取并执行录制的脚本
        $recordedScript = Get-Content $ScriptPath -Raw
        
        # 执行脚本
        $scriptBlock = [ScriptBlock]::Create($recordedScript)
        $result = Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $clientSession
        
        if ($result) {
            Write-Host "录制脚本执行成功!" -ForegroundColor Green
        } else {
            Write-Host "录制脚本执行失败!" -ForegroundColor Red
        }
    }
    catch {
        Write-Error "执行录制脚本时发生错误: $_"
    }
    finally {
        if ($clientSession) {
            $clientSession.Dispose()
        }
    }
}

# 运行录制的脚本
$recordedScriptPath = "C:\BCScripts\RecordedTest.ps1"
Invoke-RecordedScript -ScriptPath $recordedScriptPath 

# 使用凭据
try {
    $session = New-BcSession -Credential $credential -ServiceUrl $bcServerUrl
    Write-Host "连接成功!" -ForegroundColor Green
}
catch {
    Write-Error "连接失败: $_"
} 