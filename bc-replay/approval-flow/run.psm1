#!/usr/bin/env pwsh

# 设置环境变量
$env:bc-player-auth = "UserPassword"  # 或者根据实际情况使用其他认证方式
$env:bc-player-username-key = "BC_USER"
$env:bc-player-password-key = "BC_PASSWORD"

# 设置用户凭据
$env:BC_USER = "your_username"
$env:BC_PASSWORD = "your_password"

# 运行测试
$testPath = Join-Path $PSScriptRoot "*.yml"
npx replay $testPath -StartAddress "https://your-bc-url" -Authentication UserPassword