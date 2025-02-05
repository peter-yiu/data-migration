# 通用的测试辅助函数模块
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR")]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Read-ExcelData {
    param(
        [string]$ExcelPath,
        [string]$SheetName
    )
    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $workbook = $excel.Workbooks.Open($ExcelPath)
        $sheet = $workbook.Sheets($SheetName)

        $data = @()
        $row = 2 # 假设第一行是标题
        while ($sheet.Cells($row, 1).Text -ne "") {
            $rowData = @{}
            $col = 1
            while ($sheet.Cells(1, $col).Text -ne "") {
                $header = $sheet.Cells(1, $col).Text
                $value = $sheet.Cells($row, $col).Text
                $rowData[$header] = $value
                $col++
            }
            $data += $rowData
            $row++
        }
        return $data
    }
    finally {
        if ($workbook) { $workbook.Close($false) }
        if ($excel) { $excel.Quit() }
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
} 