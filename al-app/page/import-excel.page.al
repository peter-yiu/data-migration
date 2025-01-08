codeunit 50100 "Excel Import Management"
{
    procedure ImportExcelToTable()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        SheetName: Text;
        InStream: InStream;
    begin
        // 使用 File Management 上传 Excel 文件
        FileName := FileManagement.BLOBImport(TempBlob, '选择Excel文件');
        if FileName = '' then
            exit;
        
        TempBlob.CreateInStream(InStream);
        SheetName := '工作表1';
        
        // 读取 Excel 内容到临时缓冲区
        TempExcelBuffer.OpenBookStream(InStream, SheetName);
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
        ErrorLog: Text;
        SuccessCount: Integer;
        ErrorCount: Integer;
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

        // 初始化计数器
        SuccessCount := 0;
        ErrorCount := 0;
        ErrorLog := '';

        // 逐行处理数据
        ItemNo := 1;
        for RowNo := 2 to MaxRowCount do begin
            Clear(ImportedData);
            ImportedData.Init();
            ImportedData."Batch No." := CurrentBatchNo;
            ImportedData."Item No." := ItemNo;
            
            // 读取并验证数据
            if not ValidateAndAssignRowData(TempExcelBuffer, RowNo, ImportedData, ErrorLog) then begin
                ErrorCount += 1;
                ErrorLog += StrSubstNo('行号 %1: 数据验证失败\', RowNo);
                continue;
            end;

            // 插入记录
            if ImportedData.Insert() then begin
                SuccessCount += 1;
                ItemNo += 1;
            end else begin
                ErrorCount += 1;
                ErrorLog += StrSubstNo('行号 %1: 插入记录失败\', RowNo);
            end;
        end;

        // 显示导入结果
        if ErrorCount = 0 then
            Message('导入完成！共成功导入 %1 条记录，批次号：%2', SuccessCount, CurrentBatchNo)
        else
            if Confirm(StrSubstNo('导入完成！\成功：%1 条\失败：%2 条\是否查看错误日志？', 
                SuccessCount, ErrorCount)) then
                Message(ErrorLog);
    end;

    local procedure ValidateAndAssignRowData(var TempExcelBuffer: Record "Excel Buffer" temporary; 
        RowNo: Integer; var ImportedData: Record "Imported Excel Data"; var ErrorLog: Text): Boolean
    var
        TypeText: Text;
        IsValid: Boolean;
    begin
        IsValid := true;

        // 读取类型并验证
        GetValueAtCell(TempExcelBuffer, RowNo, 1, TypeText);
        TypeText := UpperCase(TypeText);
        if (TypeText <> 'P') and (TypeText <> 'C') then begin
            ErrorLog += StrSubstNo('行号 %1: 类型必须是 P 或 C\', RowNo);
            IsValid := false;
        end else
            ImportedData.Type := if(TypeText = 'P', ImportedData.Type::P, ImportedData.Type::C);

        // 根据类型验证必填字段
        if TypeText = 'C' then begin
            // 公司类型验证
            GetValueAtCell(TempExcelBuffer, RowNo, 2, ImportedData."Company Name");
            if ImportedData."Company Name" = '' then begin
                ErrorLog += StrSubstNo('行号 %1: 公司名称不能为空\', RowNo);
                IsValid := false;
            end;
        end else begin
            // 个人类型验证
            GetValueAtCell(TempExcelBuffer, RowNo, 3, ImportedData."First Name");
            GetValueAtCell(TempExcelBuffer, RowNo, 4, ImportedData."Last Name");
            if (ImportedData."First Name" = '') or (ImportedData."Last Name" = '') then begin
                ErrorLog += StrSubstNo('行号 %1: 个人类型必须填写姓名\', RowNo);
                IsValid := false;
            end;
        end;

        // 护照号码验证（所有类型都必填）
        GetValueAtCell(TempExcelBuffer, RowNo, 5, ImportedData."Passport No.");
        if ImportedData."Passport No." = '' then begin
            ErrorLog += StrSubstNo('行号 %1: 护照号码不能为空\', RowNo);
            IsValid := false;
        end;

        exit(IsValid);
    end;

    local procedure GetValueAtCell(var TempExcelBuffer: Record "Excel Buffer" temporary; 
        RowNo: Integer; ColNo: Integer; var TargetField: Text)
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



