page 50101 "Search Demo List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Demo Table";
    
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
        area(Factboxes)
        {
            part(Filter; "Filter Part")
            {
                ApplicationArea = All;
                SubPageLink = "Parent No." = field("No.");
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
                
                trigger OnAction()
                begin
                    FilterRecords();
                end;
            }
        }
    }

    // 1. 基础过滤方法
    local procedure BasicFilter()
    begin
        Rec.Reset();  // 清除所有筛选
        Rec.SetRange("No.", '10000..20000');  // 范围筛选
        Rec.SetFilter(Amount, '>=%1', 1000);   // 条件筛选
        Rec.SetFilter(Description, '@*TEST*');  // 模糊匹配
        
        // 多字段组合筛选
        Rec.SetCurrentKey("Posting Date", "Document Type");  // 设置排序键
        Rec.SetAscending("Posting Date", false);  // 设置降序
    end;

    // 2. 高级过滤方法
    local procedure AdvancedFilter()
    var
        FilterPageBuilder: FilterPageBuilder;
    begin
        FilterPageBuilder.AddTable('Demo Table', Database::"Demo Table");
        FilterPageBuilder.AddField('Demo Table', "No.");
        FilterPageBuilder.AddField('Demo Table', Description);
        
        if FilterPageBuilder.RunModal() then begin
            Rec.SetView(FilterPageBuilder.GetView('Demo Table'));
            CurrPage.Update(false);
        end;
    end;

    // 3. 动态过滤
    local procedure DynamicFilter()
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(Database::"Demo Table");
        FieldRef := RecRef.Field(Rec.FieldNo("No."));
        FieldRef.SetFilter('10000..20000');
        Rec.SetView(RecRef.GetView());
    end;

    // 4. 日期筛选
    local procedure DateFilter()
    begin
        Rec.SetRange("Posting Date", CalcDate('<-CM>', WorkDate()), WorkDate());  // 本月
        Rec.SetFilter("Due Date", '>=%1', CalcDate('<+1M>', WorkDate()));        // 一个月后
    end;

    // 5. 关联表筛选
    local procedure RelatedTableFilter()
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("Country/Region Code", 'CN');
        if Customer.FindSet() then
            Rec.SetFilter("Customer No.", Customer.GetFilter("No."));
    end;

    // 6. 保存筛选条件
    local procedure SaveFilter()
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.SavePageFilters(Page::"Search Demo List", Rec.GetView());
    end;

    // 7. 使用临时表筛选
    local procedure TempTableFilter()
    var
        TempRec: Record "Demo Table" temporary;
    begin
        // 将筛选后的记录复制到临时表
        if Rec.FindSet() then
            repeat
                TempRec := Rec;
                TempRec.Insert();
            until Rec.Next() = 0;
    end;

    // 8. 使用查询优化筛选
    local procedure QueryFilter()
    var
        DemoQuery: Query "Demo Query";
    begin
        DemoQuery.SetRange(Amount_Filter, 1000, 9999);
        DemoQuery.Open();
        while DemoQuery.Read() do begin
            // 处理查询结果
        end;
    end;
}

说明：

实际开发中的重要知识点：
1.基础筛选方法：
    SetRange: 设置范围筛选
    SetFilter: 设置条件筛选
    GetFilter: 获取当前筛选条件
    Reset: 清除所有筛选

2. 筛选符号：
   SetFilter(Field, '10000..20000');    // 范围
   SetFilter(Field, '>=%1', 1000);      // 大于等于
   SetFilter(Field, '<>%1', '');        // 不等于
   SetFilter(Field, '@*TEST*');         // 包含
   SetFilter(Field, '@*TEST|DEMO');     // 或条件
3. 日期筛选：

   SetRange("Date", CalcDate('<-CM>', WorkDate()));     // 本月开始
   SetRange("Date", CalcDate('<CY>', WorkDate()));      // 本年
   SetRange("Date", CalcDate('<-1D>', WorkDate()));     // 昨天

4. 性能优化：   
    使用 SetCurrentKey 设置正确的排序键
    避免使用 @* 这样的模糊匹配
    考虑使用查询而不是复杂的表筛选
    使用 FindSet 而不是 Find('-')

5.用户界面相关：    
  CurrPage.Update(false);  // 更新页面，false表示不重新获取记录
   CurrPage.SetSelectionFilter(Rec);  // 获取用户选择的记录


6.常见错误处理：   

7.高级功能：
  使用 FilterPageBuilder 创建动态筛选页面
  使用 RecordRef 和 FieldRef 进行动态字段操作
  使用临时表进行复杂数据处理

8.最佳实践：  
  始终在 FindSet 之前使用 Reset
  使用有意义的变量名
  添加适当的注释
  考虑性能影响
  处理空记录情况