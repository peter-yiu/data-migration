# BC Web 客户端录制的脚本
try {
    # 使用 UI 自动化命令
    $session = New-BcSession -Credential $credential -ServiceUrl $bcServerUrl
    
    # 打开客户列表页面
    Open-BcPage -Session $session -PageId 21  # 客户列表页面
    
    # 创建新客户
    $customerCard = New-BcRecord -Session $session -TableName 'Customer'
    $customerCard.'No.' = '10000'
    $customerCard.Name = '测试客户'
    $customerCard.'Address' = '测试地址'
    $customerCard.'Phone No.' = '12345678'
    Save-BcRecord -Record $customerCard
    
    # 验证客户是否创建成功
    $customer = Get-BcRecord -Session $session -TableName 'Customer' -Filter "No eq '10000'"
    if ($customer) {
        Write-Host "客户创建成功" -ForegroundColor Green
    } else {
        throw "客户创建失败"
    }
}
catch {
    Write-Error "执行失败: $($_.Exception.Message)"
    throw
}
finally {
    # 关闭会话
    if ($session) {
        Close-BcSession -Session $session
    }
} 