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
    }