@echo off
setlocal EnableDelayedExpansion
title Fedda Hub - Custom Node Fixer V2
cd /d "%~dp0"
cd ..
set "PYTHON=python_embeded\python.exe"
set "NODES=ComfyUI\custom_nodes"

echo ============================================================================
echo   FEDDA HUB - CUSTOM NODE REPAIR V2
echo ============================================================================
echo.
echo This script will:
echo 1. Remove ARCHIVED/BROKEN nodes that cause startup errors
echo 2. Install missing Python dependencies
echo 3. Upgrade BitsAndBytes to official version (CUDA 12.4 support)
echo.
echo IMPORTANT: Please CLOSE ComfyUI before continuing!
echo.
pause

if not exist "%PYTHON%" (
    echo [ERROR] Python not found at %PYTHON%
    pause
    exit /b
)

echo.
echo [1/3] Removing Archived Nodes...
if exist "%NODES%\ComfyUI-AutoConnect" (
    echo - Removing ComfyUI-AutoConnect (Archived)...
    rmdir /s /q "%NODES%\ComfyUI-AutoConnect"
)
if exist "%NODES%\ComfyUI-Custom-Nodes" (
    echo - Removing ComfyUI-Custom-Nodes [Zuellni] (Archived)...
    rmdir /s /q "%NODES%\ComfyUI-Custom-Nodes"
)

echo.
echo [2/3] Installing missing modules (ftfy, wget)...
"%PYTHON%" -m pip install ftfy wget google-generativeai --upgrade
if %errorlevel% neq 0 echo [WARNING] Failed to install modules.

echo.
echo [3/3] Upgrading BitsAndBytes (v0.48.1+ for CUDA 12.4)...
"%PYTHON%" -m pip uninstall -y bitsandbytes
"%PYTHON%" -m pip install "bitsandbytes>=0.48.1" --prefer-binary
if %errorlevel% neq 0 echo [WARNING] Failed to install bitsandbytes.

echo.
echo ============================================================================
echo   REPAIR COMPLETE
echo ============================================================================
echo.
echo Restart ComfyUI and check logs.
echo.
pause
