try {
    # 导入SQLPS模块以使用Invoke-Sqlcmd
    Import-Module SQLPS -DisableNameChecking

    # 在这里添加您的Invoke-Sqlcmd命令
    # 例如:
    Invoke-Sqlcmd -ServerInstance "YourServer" `
                  -Database "YourDatabase" `
                  -InputFile "your_script.sql"
    
    # 如果需要执行存储过程:
    Invoke-Sqlcmd -ServerInstance "YourServer" `
                  -Database "YourDatabase" `
                  -Query "EXEC YourStoredProcedure"

} catch {
    # 输出错误信息
    Write-Error $_.Exception.Message
    # 确保PowerShell脚本失败时退出码不为0
    exit 1
} 