try {
    # 使用SqlServer模块替代SQLPS（推荐）
    Import-Module SqlServer -ErrorAction Stop

    # 设置错误处理
    $ErrorActionPreference = "Stop"

    # SQL命令执行
    $result = Invoke-Sqlcmd -ServerInstance "YourServer" `
                           -Database "YourDatabase" `
                           -InputFile "your_script.sql" `
                           -ErrorAction Stop `
                           -QueryTimeout 0

    # if ($result -eq $null) {
     if ($null -eq $result) {
        throw "SQL执行返回空结果，可能发生错误"
    }

    # 检查SQL错误（某些SQL错误可能不会触发PowerShell异常）
    # if ($result -eq $null) {
    #     throw "SQL执行返回空结果，可能发生错误"
    # }

} catch {
    Write-Error "执行SQL时发生错误: $($_.Exception.Message)"
    #$host.SetShouldExit(1)  # 设置PowerShell宿主的退出码
    exit 1                   # PowerShell脚本退出，并返回错误码1
}