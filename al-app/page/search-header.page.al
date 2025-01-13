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
                Caption = '搜索';
                
                trigger OnAction()
                begin
                    ProcessSearch();
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
                // 组合搜索文本并去除前后空格
                SearchText := DelChr(
                    StrSubstNo('%1 %2 %3',
                        SearchHeader."Company Name",
                        SearchHeader."First Name",
                        SearchHeader."Last Name"
                    ), '<>', ' '  // 去除前后空格
                );
                
                // 只有当 SearchText 不为空时才调用处理程序
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
        SearchParameters."Min. Score" := 0.7;  // 设置最小匹配分数
        SearchParameters."Max. Results" := 100; // 设置最大结果数
        
        // 执行搜索
        ScrutinyMgt.Search(
            SearchParameters,  // 搜索参数
            SearchResult      // 搜索结果
        );

        // 处理搜索结果
        if SearchResult.FindSet() then begin
            repeat
                // 这里处理每个搜索结果
                // SearchResult 包含了匹配度信息和匹配到的记录信息
                ProcessScrutinyResult(SearchResult);
            until SearchResult.Next() = 0;
        end;
    end;

    local procedure ProcessScrutinyResult(var SearchResult: Record "Scrutiny Search Result" temporary)
    begin
        // 处理每个搜索结果
        // 例如：
        // - 记录匹配结果
        // - 更新状态
        // - 生成报告等
    end;
} 