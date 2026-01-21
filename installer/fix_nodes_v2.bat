@echo off
setlocal EnableDelayedExpansion
title Fedda Hub - Custom Node Fixer V2
cd /d "%~dp0"
cd ..
set "PYTHON=python_embeded\python.exe"

echo ============================================================================
echo   FEDDA HUB - CUSTOM NODE REPAIR V2
echo ============================================================================
echo.
echo This script will install remaining missing dependencies:
echo - ComfyUI-WanVideoWrapper (ftfy)
echo - ComfyUI_LayerStyle_Advance (wget)
echo - Patching BitsAndBytes for CUDA 12.4
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
echo [1/3] Installing missing modules (ftfy, wget)...
"%PYTHON%" -m pip install ftfy wget
if %errorlevel% neq 0 echo [WARNING] Failed to install modules.

echo.
echo [2/3] Verifying Google Generative AI...
"%PYTHON%" -m pip install --upgrade --force-reinstall google-generativeai
if %errorlevel% neq 0 echo [WARNING] Failed to reinstall google-generativeai.

echo.
echo [3/3] Patching BitsAndBytes for CUDA 12.4...
"%PYTHON%" -c "import os; import shutil; import bitsandbytes as bnb; bnb_path = os.path.dirname(bnb.__file__); dll_src = os.path.join(bnb_path, 'libbitsandbytes_cuda118.dll'); dll_dst = os.path.join(bnb_path, 'libbitsandbytes_cuda124.dll'); print(f'Checking B&B path: {bnb_path}'); print(f'Looking for: {dll_src}'); shutil.copy2(dll_src, dll_dst) if os.path.exists(dll_src) and not os.path.exists(dll_dst) else None; print('Patch applied if needed.')"

echo.
echo ============================================================================
echo   REPAIR COMPLETE
echo ============================================================================
echo.
echo Restart ComfyUI and check logs.
echo.
pause
