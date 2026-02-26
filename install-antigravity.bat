@echo off
REM Quick launcher for Islands Dark Antigravity installer
REM This runs the PowerShell installer with appropriate execution policy

echo Islands Dark Theme - Antigravity Installer
echo ==========================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0install-antigravity.ps1"

pause
