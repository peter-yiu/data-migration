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
    begin
        SearchHeader.Reset();
        SearchHeader.SetRange(Status, true);  
        
        // 第一步：收集所有搜索文本
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
                    SearchTexts.Add(SearchText);
            until SearchHeader.Next() = 0;
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
} 