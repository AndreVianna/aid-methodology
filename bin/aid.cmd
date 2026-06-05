@echo off
:: aid.cmd — CMD entry point for the aid CLI.
:: Tries pwsh (PowerShell 7+) first, falls back to powershell (Windows PowerShell 5.1).
:: Installed at %AID_HOME%\bin\aid.cmd so that `aid` resolves in cmd.exe AND pwsh.
setlocal

set "AID_CMD_DIR=%~dp0"
set "AID_CMD_DIR=%AID_CMD_DIR:~0,-1%"
set "AID_PS1=%AID_CMD_DIR%\aid.ps1"

where pwsh >nul 2>nul
if %errorlevel%==0 (
    pwsh -NoLogo -NonInteractive -File "%AID_PS1%" %*
    exit /b %errorlevel%
)

where powershell >nul 2>nul
if %errorlevel%==0 (
    powershell -NoLogo -NonInteractive -File "%AID_PS1%" %*
    exit /b %errorlevel%
)

echo ERROR: aid: neither pwsh nor powershell found on PATH. Install PowerShell to use the aid CLI. >&2
exit /b 1
