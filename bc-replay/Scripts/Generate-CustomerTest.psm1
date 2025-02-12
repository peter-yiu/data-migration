param(
    [string]$ExcelPath = "C:\TestData\customers.xlsx",
    [string]$SheetName = "NewCustomers",
    [string]$OutputPath = ".\recordings",
    [string]$TemplatePath = ".\Templates\create-customer-test.yml"
)

# 导入辅助模块
Import-Module "$PSScriptRoot\..\Modules\TestHelper.psm1" -Force

try {
    # 创建输出目录
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    Write-Log "开始读取客户测试数据..."

    # 读取测试数据
    $customers = Read-ExcelData -ExcelPath $ExcelPath -SheetName $SheetName

    Write-Log "成功读取 $($customers.Count) 条客户数据"

    # 读取模板
    $template = Get-Content $TemplatePath -Raw

    # 生成测试脚本
    $testScript = $template -replace 
        '${data.name}', ($customers | ForEach-Object { $_.CustomerName }) -replace
        '${data.type}', ($customers | ForEach-Object { $_.CustomerType }) -replace
        '${data.contact}', ($customers | ForEach-Object { $_.ContactPerson }) -replace
        '${data.phone}', ($customers | ForEach-Object { $_.Phone })

    # 保存生成的测试脚本
    $scriptPath = Join-Path $OutputPath "create-customer-test.yml"
    $testScript | Out-File -FilePath $scriptPath -Encoding UTF8

    Write-Log "测试脚本已生成: $scriptPath"
}
catch {
    Write-Log "错误: $_" -Level ERROR
    throw
} 