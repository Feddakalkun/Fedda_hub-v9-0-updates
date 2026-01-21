@echo off
setlocal EnableDelayedExpansion

title Fedda Hub - Universal Installer
cd /d "%~dp0"

echo ============================================================================
echo   FEDDA HUB ^& COMFYUI - UNIVERSAL INSTALLER
echo ============================================================================
echo.
echo This script will set up the entire ecosystem:
echo 1. ComfyUI (Generation Engine) + Custom Nodes + TTS
echo 2. Fedda Hub (Dashboard) + Dependencies
echo 3. Ollama (AI Chat Engine)
echo.
echo LOGS: All installation logs will be saved to logs/ folder
echo       Check install_summary.txt for results
echo       See INSTALLATION_LOGS_GUIDE.md for troubleshooting
echo.

:: Admin Check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs -Wait"
    exit /b
)

echo.
echo [Universal Installer] Handing over to PowerShell core...
echo.

powershell -ExecutionPolicy Bypass -File "scripts\core\install.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Installation failed!
    pause
    exit /b %errorlevel%
)

echo.
echo ============================================================================
echo   INSTALLATION COMPLETE!
echo ============================================================================
echo.
echo IMPORTANT: Please run 'update.bat' to fetch the latest updates and hotfixes!
echo            and 'download-emmy.bat' to get the demo character.
echo.
echo To start the system, run: run.bat
echo.
pause
