codeunit 139500 "Customer Tests"
{
    Subtype = Test;
    
    [Test]
    procedure TestCustomerCreation()
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        // 准备
        CustomerNo := '10000';
        
        // 执行
        Customer.Init();
        Customer.Validate("No.", CustomerNo);
        Customer.Validate(Name, '测试客户');
        Customer.Insert(true);
        
        // 验证
        Assert.IsTrue(Customer.Get(CustomerNo), '客户未创建成功');
        Assert.AreEqual('测试客户', Customer.Name, '客户名称不匹配');
    end;
} 