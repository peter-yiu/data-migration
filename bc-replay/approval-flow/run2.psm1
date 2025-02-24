# 在 run.ps1 中添加
$approvalNo = $null

# User1 提交修改
$env:BC_USER = "user1"
$env:BC_PASSWORD = "user1_password"
Write-Host "Running user1 submit test..."
$result = npx replay ./user1-submit.yml -StartAddress "https://your-bc-url"
# 从输出中获取审批号
$approvalNo = $result | Select-String -Pattern "Approval No: (\w+)" | ForEach-Object { $_.Matches.Groups[1].Value }

# 设置环境变量
$env:APPROVAL_NO = $approvalNo

# Manager1 审批
$env:BC_USER = "manager1"
$env:BC_PASSWORD = "manager1_password" 
Write-Host "Running manager1 approve test with approval no: $approvalNo"
npx replay ./manager1-approve.yml -StartAddress "https://your-bc-url"





这里使用 process.env.APPROVAL_NO 保存审批号,但在 PowerShell 环境中,这个变量可能无法正确传递到下一个测试脚本。
建议修改为:




b. 选择器问题:
需要确保 yml 文件中的选择器与实际 BC 页面元素匹配,比如:
.entity-table
.edit-button
.message-dialog
.approval-number
.approval-table
等
建议先用浏览器开发者工具验证这些选择器。
总结:
基本框架是可以运行的
但需要解决审批号传递问题
需要验证选择器的准确性
建议先在 headed 模式下测试:


npx replay ./user1-submit.yml -StartAddress "https://your-bc-url" -Headed



要让脚本稳定运行,建议进行以下修改:
添加更多的等待和验证步骤
增加错误处理和重试机制
3. 添加详细的日志记录
使用更可靠的方式传递审批号
考虑添加测试结果验证步骤
需要我帮你修改脚本来解决这些问题吗？