codeunit 50100 "Excel Import Management"
{
    procedure ImportExcelToTable()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileName: Text;
        SheetName: Text;
        UploadResult: Boolean;
        FileManagement: Codeunit "File Management";
    begin
        // 上传 Excel 文件
        UploadResult := UploadIntoStream('选择Excel文件', '', '所有文件 (*.*)|*.*', FileName, TempExcelBuffer.FileStream);
        if not UploadResult then
            exit;

        SheetName := '工作表1';
        
        // 读取 Excel 内容到临时缓冲区
        TempExcelBuffer.OpenBookStream(TempExcelBuffer.FileStream, SheetName);
        TempExcelBuffer.ReadSheet();

        // 处理数据并插入到目标表
        ProcessExcelData(TempExcelBuffer);
    end;

    local procedure ProcessExcelData(var TempExcelBuffer: Record "Excel Buffer" temporary)
    var
        ImportedData: Record "Imported Excel Data";
        LastBatchNo: Integer;
        CurrentBatchNo: Integer;
        RowNo: Integer;
        ItemNo: Integer;
        MaxRowCount: Integer;
    begin
        // 获取最后一个批次号
        if ImportedData.FindLast() then
            LastBatchNo := ImportedData."Batch No."
        else
            LastBatchNo := 0;
        
        CurrentBatchNo := LastBatchNo + 1;
        
        // 获取最大行数
        TempExcelBuffer.SetRange("Row No.", 2, 999999);  // 跳过标题行
        if TempExcelBuffer.FindLast() then
            MaxRowCount := TempExcelBuffer."Row No.";

        // 逐行处理数据
        ItemNo := 1;
        for RowNo := 2 to MaxRowCount do begin
            ImportedData.Init();
            ImportedData."Batch No." := CurrentBatchNo;
            ImportedData."Item No." := ItemNo;
            
            // 读取每一列的数据并赋值给表字段
            GetValueAtCell(TempExcelBuffer, RowNo, 1, ImportedData.Field1);  // 第1列
            GetValueAtCell(TempExcelBuffer, RowNo, 2, ImportedData.Field2);  // 第2列
            // ... 添加更多字段映射

            // 插入记录
            if ImportedData.Insert() then;
            ItemNo += 1;
        end;

        Message('导入完成！共导入 %1 条记录，批次号：%2', ItemNo - 1, CurrentBatchNo);
    end;

    local procedure GetValueAtCell(var TempExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; ColNo: Integer; var TargetField: Text)
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.SetRange("Row No.", RowNo);
        TempExcelBuffer.SetRange("Column No.", ColNo);
        if TempExcelBuffer.FindFirst() then
            TargetField := TempExcelBuffer."Cell Value as Text"
        else
            TargetField := '';
    end;
}



