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
        SearchText: Text;
    begin
        SearchHeader.Reset();
        SearchHeader.SetRange(Status, true);  
        
        if SearchHeader.FindSet() then begin
            repeat
                SearchText := DelChr(
                    StrSubstNo('%1 %2 %3',
                        SearchHeader."Company Name",
                        SearchHeader."First Name",
                        SearchHeader."Last Name"
                    ), '<>', ' '
                );
                
                if SearchText <> '' then
                    ProcessSearchText(SearchText);
            until SearchHeader.Next() = 0;
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
        ScrutinyMgt: Codeunit "Scrutiny Management";
        SearchParameters: Record "Scrutiny Parameters" temporary;
        SearchResult: Record "Scrutiny Search Result" temporary;
        SearchTexts: List of [Text];
        SearchText: Text;
        Entity: Record Entity;
        Client: Record Client;
        ErrorList: List of [Text];
    begin
        SearchHeader.Reset();
        SearchHeader.SetRange(Status, true);  
        
        // 第一步：收集所有搜索文本
        if SearchHeader.FindSet() then begin
            repeat
                // 根据 ClientEntityNo 获取 FormalName
                SearchText := '';
                if SearchHeader."Client Entity No." <> '' then begin
                    if CopyStr(SearchHeader."Client Entity No.", 1, 2) = 'EN' then begin
                        // 检查 Entity 表
                        if not Entity.Get(SearchHeader."Client Entity No.") then begin
                            ErrorList.Add(StrSubstNo('编号 %1 在 Entity 表中未找到匹配记录', SearchHeader."Client Entity No."));
                            continue;
                        end;
                        SearchText := Entity.FormalName;
                    end else begin
                        // 检查 Client 表
                        if not Client.Get(SearchHeader."Client Entity No.") then begin
                            ErrorList.Add(StrSubstNo('编号 %1 在 Client 表中未找到匹配记录', SearchHeader."Client Entity No."));
                            continue;
                        end;
                        SearchText := Client.FormalName;
                    end;
                end else begin
                    // Client Entity No. 为空时使用默认组合
                    SearchText := DelChr(
                        StrSubstNo('%1 %2 %3',
                            SearchHeader."Company Name",
                            SearchHeader."First Name",
                            SearchHeader."Last Name"
                        ), '<>', ' '
                    );
                end;
                
                if SearchText <> '' then
                    SearchTexts.Add(SearchText);
            until SearchHeader.Next() = 0;
        end;

        // 检查是否有错误
        if not ErrorList.IsEmpty then begin
            ShowErrorList(ErrorList);
            exit;
        end;

        // 第二步：批量搜索
        if not SearchTexts.IsEmpty then begin
            SearchParameters.Init();
            SearchParameters."Min. Score" := 0.7;
            SearchParameters."Max. Results" := 1000;
            
            ScrutinyMgt.SearchMultiple(
                SearchTexts,
                SearchParameters,
                SearchResult
            );

            if SearchResult.FindSet() then begin
                repeat
                    ProcessScrutinyResult(SearchResult);
                until SearchResult.Next() = 0;
            end;

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