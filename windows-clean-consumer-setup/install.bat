@echo off
setlocal

cd /d "%~dp0"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Administratorrechten nodig. PowerShell wordt opnieuw gestart als administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0clean-setup.ps1""'"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0clean-setup.ps1"

echo.
pause