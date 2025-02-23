@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File command2.ps1
if %ERRORLEVEL% NEQ 0 (
    echo PowerShell script failed with error level %ERRORLEVEL%
    exit /b 1
)
echo PowerShell script completed successfully
exit /b 0 