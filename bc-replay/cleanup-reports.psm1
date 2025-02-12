param(
    [int]$DaysToKeep = 30,
    [string]$ShareFolder = "\\your-server\share\test-reports"
)

try {
    # 获取所有超过指定天数的文件夹
    $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
    $oldFolders = Get-ChildItem -Path $ShareFolder -Directory |
        Where-Object { $_.CreationTime -lt $cutoffDate }

    if ($oldFolders) {
        Write-Host "正在清理 $($oldFolders.Count) 个旧报告文件夹..."
        foreach ($folder in $oldFolders) {
            Write-Host "删除: $($folder.FullName)"
            Remove-Item -Path $folder.FullName -Recurse -Force
        }
        Write-Host "清理完成"
    } else {
        Write-Host "没有需要清理的旧报告"
    }
}
catch {
    Write-Error "清理过程中出错: $_"
    exit 1
} 