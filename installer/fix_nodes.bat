@echo off
setlocal EnableDelayedExpansion
title Fedda Hub - Custom Node Fixer
cd /d "%~dp0"
cd ..
set "PYTHON=python_embeded\python.exe"

echo ============================================================================
echo   FEDDA HUB - CUSTOM NODE REPAIR
echo ============================================================================
echo.
echo This script will fix missing dependencies for:
echo - ComfyUI-GGUF (gguf)
echo - ComfyUI-Impact-Pack (segment-anything)
echo - ComfyUI-Inspire-Pack (webcolors)
echo - ComfyUI-Fill-Nodes (google-generativeai)
echo - ComfyUI-Crystools (cpuinfo)
echo - OpenCV / LayerStyle issues
echo - BitsAndBytes (CUDA support)
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
echo [1/4] Installing missing Python modules...
"%PYTHON%" -m pip install gguf segment-anything webcolors google-generativeai py-cpuinfo
if %errorlevel% neq 0 echo [WARNING] Failed to install some modules.

echo.
echo [2/4] Fixing BitsAndBytes (Windows + CUDA)...
echo Uninstalling existing bitsandbytes...
"%PYTHON%" -m pip uninstall -y bitsandbytes
echo Installing Windows-compatible bitsandbytes...
"%PYTHON%" -m pip install https://github.com/jllllll/bitsandbytes-windows-webui/releases/download/wheels/bitsandbytes-0.41.2.post2-py3-none-win_amd64.whl
if %errorlevel% neq 0 echo [WARNING] Failed to install bitsandbytes wheel.

echo.
echo [3/4] Fixing OpenCV conflicts...
echo Uninstalling conflicting wrappers...
"%PYTHON%" -m pip uninstall -y opencv-python opencv-python-headless opencv-contrib-python opencv-contrib-python-headless
echo Installing clean OpenCV packages...
"%PYTHON%" -m pip install opencv-python opencv-contrib-python
if %errorlevel% neq 0 echo [WARNING] Failed to fix OpenCV.

echo.
echo [4/4] Verifying installations...
"%PYTHON%" -c "import gguf; import segment_anything; import webcolors; import cv2; print('Verification Successful!')"

echo.
echo ============================================================================
echo   REPAIR COMPLETE
echo ============================================================================
echo.
echo You can now restart ComfyUI.
echo.
pause
