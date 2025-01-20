page 50101 "Search Header List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Search Header";
    
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = All;
                }
                field("Last Name"; Rec."Last Name")
                {
                    ApplicationArea = All;
                }
                field("Client Entity No."; Rec."Client Entity No.")
                {
                    ApplicationArea = All;
                    StyleExpr = ClientEntityNoStyle;
                    
                    trigger OnValidate()
                    begin
                        ValidateClientEntityNo();
                    end;
                }
                // 其他需要显示的字段...
            }
        }
    }
    
    actions
    {
        area(Processing)
        {
            action(Search)
            {
                ApplicationArea = All;
                Image = Find;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Caption = '单条搜索';
                
                trigger OnAction()
                begin
                    ProcessSearch();
                end;
            }
            action(BatchSearch)
            {
                ApplicationArea = All;
                Image = BatchProcessing;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Caption = '批量搜索';
                
                trigger OnAction()
                begin
                    ProcessBatchSearch();
                end;
            }
        }
    }

    local procedure ProcessSearch()
    var
        SearchHeader: Record "Search Header";
        Entity: Record Entity;
        ParticularsHistory: Record "Particulars History";
        SearchText: Text;
        ErrorList: List of [Text];
    begin
        SearchHeader.Reset();
        SearchHeader.SetRange(Status, true);  
        
        if SearchHeader.FindSet() then begin
            repeat
                // 1. 检查 Entity No.
                if SearchHeader."Entity No." <> '' then begin
                    // 匹配 Entity 表
                    if not Entity.Get(SearchHeader."Entity No.") then begin
                        ErrorList.Add(StrSubstNo('编号 %1 在 Entity 表中未找到匹配记录', SearchHeader."Entity No."));
                        continue;
                    end;
                    
                    // 使用当前 Formal Name 搜索
                    SearchText := Entity.FormalName;
                    if SearchText <> '' then
                        ProcessSearchText(SearchText);

                    // 搜索历史名称
                    ParticularsHistory.Reset();
                    ParticularsHistory.SetRange("No.", SearchHeader."Entity No.");
                    ParticularsHistory.SetRange("Change Type", ParticularsHistory."Change Type"::Name);
                    if ParticularsHistory.FindSet() then begin
                        repeat
                            if ParticularsHistory."Old Formal Name" <> '' then
                                ProcessSearchText(ParticularsHistory."Old Formal Name");
                        until ParticularsHistory.Next() = 0;
                    end;
                end else begin
                    // 3. Entity No. 为空时的处理
                    if SearchHeader."Company Name" <> '' then begin
                        // 3.1 Company Name 不为空
                        if SearchHeader."Company Name" <> '' then
                            ProcessSearchText(SearchHeader."Company Name");
                        
                        if SearchHeader."Previous Name" <> '' then
                            ProcessSearchText(SearchHeader."Previous Name");
                            
                        if SearchHeader."Alias Name" <> '' then
                            ProcessSearchText(SearchHeader."Alias Name");
                    end else begin
                        // 3.2 Company Name 为空
                        if (SearchHeader."First Name" <> '') or (SearchHeader."Last Name" <> '') then
                            ProcessSearchText(DelChr(StrSubstNo('%1 %2', 
                                SearchHeader."First Name", 
                                SearchHeader."Last Name"
                            ), '<>', ' '));
                            
                        if SearchHeader."Previous Name" <> '' then
                            ProcessSearchText(SearchHeader."Previous Name");
                            
                        if SearchHeader."Alias Name" <> '' then
                            ProcessSearchText(SearchHeader."Alias Name");
                    end;
                end;
            until SearchHeader.Next() = 0;
        end;

        // 检查是否有错误
        if not ErrorList.IsEmpty then begin
            ShowErrorList(ErrorList);
            exit;
        end;
    end;

    local procedure ProcessSearchText(SearchText: Text)
    var
        ScrutinyMgt: Codeunit "Scrutiny Management";
        ScrutinySetup: Record "Scrutiny Setup";
        SearchResult: Record "Scrutiny Search Result" temporary;
        SearchParameters: Record "Scrutiny Parameters" temporary;
    begin
        // 初始化搜索参数
        SearchParameters.Init();
        SearchParameters."Search Text" := SearchText;
        SearchParameters."Min. Score" := 0.7;
        SearchParameters."Max. Results" := 100;
        
        // 执行搜索
        ScrutinyMgt.Search(
            SearchParameters,
            SearchResult
        );

        // 处理搜索结果
        if SearchResult.FindSet() then begin
            repeat
                ProcessScrutinyResult(SearchResult);
            until SearchResult.Next() = 0;
        end;
    end;

    local procedure ProcessBatchSearch()
    var
        SearchHeader: Record "Search Header";
        Entity: Record Entity;
        ParticularsHistory: Record "Particulars History";
        SearchTexts: List of [Text];
        SearchText: Text;
        ErrorList: List of [Text];
    begin
        SearchHeader.Reset();
        SearchHeader.SetRange(Status, true);  
        
        // 收集所有搜索文本
        if SearchHeader.FindSet() then begin
            repeat
                if SearchHeader."Entity No." <> '' then begin
                    // 匹配 Entity 表
                    if not Entity.Get(SearchHeader."Entity No.") then begin
                        ErrorList.Add(StrSubstNo('编号 %1 在 Entity 表中未找到匹配记录', SearchHeader."Entity No."));
                        continue;
                    end;
                    
                    // 添加当前 Formal Name
                    if Entity.FormalName <> '' then
                        SearchTexts.Add(Entity.FormalName);

                    // 添加历史名称
                    ParticularsHistory.Reset();
                    ParticularsHistory.SetRange("No.", SearchHeader."Entity No.");
                    ParticularsHistory.SetRange("Change Type", ParticularsHistory."Change Type"::Name);
                    if ParticularsHistory.FindSet() then begin
                        repeat
                            if ParticularsHistory."Old Formal Name" <> '' then
                                SearchTexts.Add(ParticularsHistory."Old Formal Name");
                        until ParticularsHistory.Next() = 0;
                    end;
                end else begin
                    if SearchHeader."Company Name" <> '' then begin
                        if SearchHeader."Company Name" <> '' then
                            SearchTexts.Add(SearchHeader."Company Name");
                        
                        if SearchHeader."Previous Name" <> '' then
                            SearchTexts.Add(SearchHeader."Previous Name");
                            
                        if SearchHeader."Alias Name" <> '' then
                            SearchTexts.Add(SearchHeader."Alias Name");
                    end else begin
                        if (SearchHeader."First Name" <> '') or (SearchHeader."Last Name" <> '') then
                            SearchTexts.Add(DelChr(StrSubstNo('%1 %2', 
                                SearchHeader."First Name", 
                                SearchHeader."Last Name"
                            ), '<>', ' '));
                            
                        if SearchHeader."Previous Name" <> '' then
                            SearchTexts.Add(SearchHeader."Previous Name");
                            
                        if SearchHeader."Alias Name" <> '' then
                            SearchTexts.Add(SearchHeader."Alias Name");
                    end;
                end;
            until SearchHeader.Next() = 0;
        end;

        // 检查是否有错误
        if not ErrorList.IsEmpty then begin
            ShowErrorList(ErrorList);
            exit;
        end;

        // 执行批量搜索
        if not SearchTexts.IsEmpty then begin
            ProcessBatchSearchTexts(SearchTexts);
            Message('批量搜索完成，共处理 %1 个搜索文本', SearchTexts.Count);
        end;
    end;

    local procedure ShowErrorList(var ErrorList: List of [Text])
    var
        ErrorText: Text;
        ErrorMessage: Text;
    begin
        ErrorMessage := '以下记录存在错误：\';
        foreach ErrorText in ErrorList do
            ErrorMessage += '\' + ErrorText;
        
        Error(ErrorMessage);
    end;

    local procedure ProcessScrutinyResult(var SearchResult: Record "Scrutiny Search Result" temporary)
    begin
        // 处理每个搜索结果
        // SearchResult 字段包括：
        // - "Search Text": 原始搜索文本
        // - "Score": 匹配分数
        // - "Table ID": 匹配到的表ID
        // - "Record ID": 匹配到的记录ID
        // 等等...
    end;

    var
        [InDataSet]
        ClientEntityNoStyle: Text;

    local procedure ValidateClientEntityNo()
    var
        Entity: Record Entity;
        Client: Record Client;
        IsValid: Boolean;
    begin

 // 只在未完成搜索的记录上执行验证
    if Rec."Search Completed" then begin
        ClientEntityNoStyle := '';  // 已完成搜索的记录不显示样式
        exit;
    end;

        if Rec."Client Entity No." = '' then begin
            ClientEntityNoStyle := '';
            exit;
        end;

        if CopyStr(Rec."Client Entity No.", 1, 2) = 'EN' then begin
            // 检查 Entity 表
            IsValid := Entity.Get(Rec."Client Entity No.");
        end else begin
            // 检查 Client 表
            IsValid := Client.Get(Rec."Client Entity No.");
        end;

        // 设置样式
        ClientEntityNoStyle := if(IsValid, '', 'Unfavorable');
        
        // 更新页面
        CurrPage.Update(false);
    end;

    trigger OnAfterGetRecord()
    begin
        ValidateClientEntityNo();
    end;
} 
