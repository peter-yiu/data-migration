param(
    [string]$ExcelPath = "C:\TestData\users.xlsx",
    [string]$SheetName = "Users",
    [string]$OutputPath = ".\recordings"
)

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

try {
    # 创建输出目录
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    Write-Log "开始读取Excel用户数据..."

    # 读取Excel
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $workbook = $excel.Workbooks.Open($ExcelPath)
    $sheet = $workbook.Sheets($SheetName)

    # 读取用户数据
    $users = @()
    $row = 2 # 假设第一行是标题
    while ($sheet.Cells($row, 1).Text -ne "") {
        $users += @{
            username = $sheet.Cells($row, 1).Text
            password = $sheet.Cells($row, 2).Text
            role = $sheet.Cells($row, 3).Text
        }
        $row++
    }

    Write-Log "成功读取 $($users.Count) 个用户信息"

    # 生成测试脚本
    $testScript = @"
name: "多用户参数化登录测试"

parameters:
  baseUrl: "http://localhost:8080/bc250"

variables:
  timestamp: "`${NOW:yyyyMMddHHmmss}"

iterations:
$(foreach ($user in $users) {
@"
  - data:
      username: "$($user.username)"
      password: "$($user.password)"
      role: "$($user.role)"

"@
})

steps:
  - type: "navigate"
    url: "`${parameters.baseUrl}/login"
  
  - type: "waitForSelector"
    selector: "#loginForm"
    timeout: 10000
  
  - type: "fill"
    selector: "#username"
    value: "`${data.username}"
  
  - type: "fill"
    selector: "#password"
    value: "`${data.password}"
  
  - type: "click"
    selector: "#loginButton"
  
  - type: "expect"
    selector: ".user-info"
    assertion: "toContainText"
    value: "`${data.username}"
    timeout: 10000
  
  - type: "screenshot"
    path: "c:/bc-replay/result/screenshots/`${data.username}-`${variables.timestamp}.png"
  
  - type: "click"
    selector: "#logoutButton"
  
  - type: "expect"
    selector: "#loginForm"
    assertion: "toBeVisible"
"@

    # 保存测试脚本
    $scriptPath = Join-Path $OutputPath "multi-user-login.yml"
    $testScript | Out-File -FilePath $scriptPath -Encoding UTF8

    Write-Log "测试脚本已生成: $scriptPath"
}
catch {
    Write-Log "错误: $_"
    throw
}
finally {
    # 清理Excel对象
    if ($workbook) { $workbook.Close($false) }
    if ($excel) { $excel.Quit() }
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
} 