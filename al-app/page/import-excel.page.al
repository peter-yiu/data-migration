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

    local procedure GetExcelValue(var TempExcelBuffer: Record "Excel Buffer" temporary; 
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

    // 新增：获取Excel日期值
    local procedure GetExcelDateValue(var TempExcelBuffer: Record "Excel Buffer" temporary; 
        RowNo: Integer; ColNo: Integer): Date
    var
        DateValue: Date;
        DateText: Text;
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.SetRange("Row No.", RowNo);
        TempExcelBuffer.SetRange("Column No.", ColNo);
        if TempExcelBuffer.FindFirst() then begin
            // 首先尝试使用Excel的日期值
            if TempExcelBuffer."Cell Value as Date" <> 0D then
                exit(TempExcelBuffer."Cell Value as Date");

            // 如果不是Excel日期，尝试转换文本
            DateText := TempExcelBuffer."Cell Value as Text";
            if TryConvertToDate(DateText, DateValue) then
                exit(DateValue);
        end;
        exit(0D);
    end;

    // 新增：日期转换方法
    local procedure TryConvertToDate(DateText: Text; var DateValue: Date): Boolean
    var
        DateFormatList: List of [Text];
        DateFormat: Text;
    begin
        // 初始化支持的日期格式列表
        DateFormatList.Add('<Day,2>/<Month,2>/<Year4>');
        DateFormatList.Add('<Year4>-<Month,2>-<Day,2>');
        DateFormatList.Add('<Month,2>/<Day,2>/<Year4>');
        DateFormatList.Add('<Day,2>-<Month,2>-<Year4>');

        // 尝试直接转换
        if Evaluate(DateValue, DateText) then
            exit(true);

        // 尝试不同的日期格式
        foreach DateFormat in DateFormatList do
            if Evaluate(DateValue, DateText, DateFormat) then
                exit(true);

        exit(false);
    end;

    local procedure ProcessExcelData(var TempExcelBuffer: Record "Excel Buffer" temporary)
    var
        ImportedData: Record "Imported Excel Data";
        TempImportedData: Record "Imported Excel Data" temporary;
        LastBatchNo: Integer;
        CurrentBatchNo: Integer;
        RowNo: Integer;
        ItemNo: Integer;
        MaxRowCount: Integer;
        ErrorLog: Text;
        SuccessCount: Integer;
        ErrorCount: Integer;
        ImportDate: Date;
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
        ErrorCount := 0;
        ErrorLog := '';

        // 第一步：验证所有数据
        ItemNo := 1;
        for RowNo := 2 to MaxRowCount do begin
            TempImportedData.Init();
            TempImportedData."Batch No." := CurrentBatchNo;
            TempImportedData."Item No." := ItemNo;
            
            // 读取并验证数据
            if not ValidateAndAssignRowData(TempExcelBuffer, RowNo, TempImportedData, ErrorLog) then begin
                ErrorCount += 1;
                ErrorLog += StrSubstNo('行号 %1: 数据验证失败\', RowNo);
                continue;
            end;

            // 获取日期字段（假设在第6列）
            ImportDate := GetExcelDateValue(TempExcelBuffer, RowNo, 6);
            if ImportDate = 0D then begin
                ErrorCount += 1;
                ErrorLog += StrSubstNo('行号 %1: 日期格式无效\', RowNo);
                continue;
            end;
            TempImportedData."Import Date" := ImportDate;
            
            // 如果验证通过，保存到临时表
            if ErrorCount = 0 then begin
                TempImportedData.Insert();
                ItemNo += 1;
            end;
        end;

        // 如果有任何错误，直接返回
        if ErrorCount > 0 then begin
            Message(StrSubstNo('验证失败！发现 %1 个错误：\%2', ErrorCount, ErrorLog));
            exit;
        end;

        // 第二步：所有数据验证通过后，批量插入
        SuccessCount := 0;
        if TempImportedData.FindSet() then
            repeat
                Clear(ImportedData);
                ImportedData := TempImportedData;
                if ImportedData.Insert() then
                    SuccessCount += 1
                else begin
                    ErrorCount += 1;
                    ErrorLog += StrSubstNo('行号 %1: 插入记录失败\', TempImportedData."Item No.");
                end;
            until TempImportedData.Next() = 0;

        // 显示导入结果
        if ErrorCount = 0 then
            Message('导入完成！共成功导入 %1 条记录，批次号：%2', SuccessCount, CurrentBatchNo)
        else
            Message(StrSubstNo('导入失败！所有数据已回滚。\错误信息：\%1', ErrorLog));
    end;

    local procedure ValidateAndAssignRowData(var TempExcelBuffer: Record "Excel Buffer" temporary; 
        RowNo: Integer; var ImportedData: Record "Imported Excel Data"; var ErrorLog: Text): Boolean
    var
        TypeText: Text;
        IsValid: Boolean;
        ImportDate: Date;
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

        // 验证日期（假设在第6列）
        ImportDate := GetExcelDateValue(TempExcelBuffer, RowNo, 6);
        if ImportDate = 0D then begin
            ErrorLog += StrSubstNo('行号 %1: 日期格式无效\', RowNo);
            IsValid := false;
        end else
            ImportedData."Import Date" := ImportDate;

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



