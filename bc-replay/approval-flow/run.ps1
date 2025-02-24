#!/usr/bin/env pwsh

# 设置环境变量
$env:bc-player-auth = "UserPassword"  # 或者根据实际情况使用其他认证方式
$env:bc-player-username-key = "BC_USER"
$env:bc-player-password-key = "BC_PASSWORD"

# User1 提交修改
$env:BC_USER = "user1"
$env:BC_PASSWORD = "user1_password"
Write-Host "Running user1 submit test..."
npx replay ./user1-submit.yml -StartAddress "https://your-bc-url"

# Manager1 审批
$env:BC_USER = "manager1" 
$env:BC_PASSWORD = "manager1_password"
Write-Host "Running manager1 approve test..."
npx replay ./manager1-approve.yml -StartAddress "https://your-bc-url" 