# 下面给出两种常见的做法，一是不在 Excel 中存储明文密码，而是存储密码的标识（比如在安全存储中的 Secret 名称），二是在 Pipeline 中使用安全变量或 Azure Key Vault 来管理敏感信息。下面的示例将演示如何修改之前的 PowerShell 脚本，在读取 Excel 用户数据时，通过 Azure Key Vault 获取实际的密码，从而避免在 Excel 中保存明文密码。
# 假设 Excel 文件中第三列仍然记录一个密码标识符（例如 Secret 名称），而实际密码已经提前存储在 Azure Key Vault 中。脚本会使用 Get-AzKeyVaultSecret 命令（需要提前安装并配置 Az.KeyVault 模块) 动态读取密码。
# 以下是修改后的脚本示例：

param(
    [string]$ExcelPath = "C:\TestData\users.xlsx",
    [string]$SheetName = "Users",
    [string]$OutputPath = ".\recordings",
    [string]$KeyVaultName = "MyKeyVault"  # Azure Key Vault 名称
)

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

# 从 Azure Key Vault 获取用户密码
function Get-UserPassword {
    param(
        [string]$VaultName,
        [string]$SecretName
    )
    try {
        # 注意：需要先登录 Azure (例如使用 Connect-AzAccount)
        $secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -ErrorAction Stop
        return $secret.SecretValueText
    }
    catch {
        Write-Log "获取 KeyVault 中的 Secret '$SecretName' 失败: $_"
        throw
    }
}

try {
    # 创建输出目录
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    Write-Log "开始读取 Excel 用户数据..."

    # 启动 Excel COM 对象
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $workbook = $excel.Workbooks.Open($ExcelPath)
    $sheet = $workbook.Sheets($SheetName)

    # 读取用户数据（假设第一行是标题，用户名在第一列，Secret 标识在第二列，角色在第三列）
    $users = @()
    $row = 2
    while ($sheet.Cells($row, 1).Text -ne "") {
        # 从 Excel 中读取 Secret 名称（不是明文密码）
        $secretName = $sheet.Cells($row, 2).Text
        # 从 Key Vault 中获取实际密码
        $actualPassword = Get-UserPassword -VaultName $KeyVaultName -SecretName $secretName

        $users += @{
            username = $sheet.Cells($row, 1).Text
            password = $actualPassword
            role     = $sheet.Cells($row, 3).Text
        }
        $row++
    }

    Write-Log "成功读取 $($users.Count) 个用户信息"

    # 生成参数化的 BC-Replay 测试脚本
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

    # 保存生成的 YAML 测试脚本
    $scriptPath = Join-Path $OutputPath "multi-user-login.yml"
    $testScript | Out-File -FilePath $scriptPath -Encoding UTF8

    Write-Log "测试脚本已生成: $scriptPath"
}
catch {
    Write-Log "错误: $_"
    throw
}
finally {
    # 清理 Excel COM 对象
    if ($workbook) { $workbook.Close($false) }
    if ($excel) { $excel.Quit() }
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}