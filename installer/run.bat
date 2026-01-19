@echo off
setlocal EnableDelayedExpansion
title Fedda Hub - Universal Launcher

:: ============================================================================
:: RE-ENTRANT SECTIONS (For separate windows)
:: ============================================================================
if "%1"==":launch_ollama" goto :launch_ollama
if "%1"==":launch_comfy" goto :launch_comfy
if "%1"==":launch_fedda_hub" goto :launch_fedda_hub
if "%1"==":launch_browser" goto :launch_browser

:: ============================================================================
:: MAIN CONFIGURATION
:: ============================================================================
cd /d "%~dp0"
set "INSTALLER_DIR=%~dp0"
:: Base Directory is the Repository Root (one level up from installer)
cd ..
set "REPO_ROOT=%CD%"
set "PYTHON=%REPO_ROOT%\python_embeded\python.exe"
set "OLLAMA_EXE=%REPO_ROOT%\ollama_embeded\ollama.exe"
set "NODE_EXE=%REPO_ROOT%\node_embeded\node.exe"
set "NPM_CMD=%REPO_ROOT%\node_embeded\npm.cmd"
set "GIT_CMD=%REPO_ROOT%\git_embeded\cmd\git.exe"

:: Set PATH for session
set "PATH=%REPO_ROOT%\python_embeded;%REPO_ROOT%\python_embeded\Scripts;%REPO_ROOT%\git_embeded\cmd;%REPO_ROOT%\node_embeded;%PATH%"

echo ============================================================================
echo   FEDDA HUB LAUNCHER (Portable)
echo ============================================================================
echo.
echo  Root Directory: %REPO_ROOT%
echo  Python: %PYTHON%
echo  Node:   %NODE_EXE%
echo.

:: 1. Start Ollama
echo [1/3] Starting Ollama LLM Engine...
start "Ollama Engine" /MIN cmd /k "call "%~f0" :launch_ollama"
timeout /t 2 /nobreak >nul

:: 2. Start ComfyUI
echo [2/3] Starting ComfyUI (Port 8188)...
start "ComfyUI Backend" /MIN cmd /k "call "%~f0" :launch_comfy"

:: 3. Start Fedda Hub (Next.js)
echo [3/3] Starting Fedda Hub Dashboard (Port 3000)...
start "Fedda Hub Dashboard" /MIN cmd /k "call "%~f0" :launch_fedda_hub"

:: 4. Start Browser Waiter
echo [INFO] Browser will open automatically when UI is ready.
start "Browser Helper" /MIN cmd /c "call "%~f0" :launch_browser"

echo.
echo System launching... 
echo Press any key to clean exit launcher (background services will keep running).
pause
exit /b

:: ============================================================================
:: SUBROUTINE: OLLAMA
:: ============================================================================
:launch_ollama
cd /d "%~dp0"
cd ..
set "REPO_ROOT=%CD%"
set "OLLAMA_EXE=%REPO_ROOT%\ollama_embeded\ollama.exe"
set "OLLAMA_MODELS=%REPO_ROOT%\ollama_embeded\models"
set "OLLAMA_HOST=127.0.0.1:11434"

if exist "%OLLAMA_EXE%" (
    echo Running Portable Ollama...
    "%OLLAMA_EXE%" serve
) else (
    echo [WARNING] Portable Ollama not found at: %OLLAMA_EXE%
    echo Trying system Ollama...
    ollama serve
)
if %errorlevel% neq 0 (
    echo [ERROR] Ollama crashed!
    pause
)
exit /b

:: ============================================================================
:: SUBROUTINE: COMFYUI
:: ============================================================================
:launch_comfy
cd /d "%~dp0"
cd ..
set "REPO_ROOT=%CD%"
set "COMFYUI_DIR=%REPO_ROOT%\ComfyUI"
set "PYTHON=%REPO_ROOT%\python_embeded\python.exe"
:: Add portable GIT and Python to PATH for this session
set "PATH=%REPO_ROOT%\python_embeded;%REPO_ROOT%\python_embeded\Scripts;%REPO_ROOT%\git_embeded\cmd;%REPO_ROOT%\node_embeded;%PATH%"

set COMFYUI_OFFLINE=1
set PYTHONUNBUFFERED=1
set PYTHONIOENCODING=utf-8
set PYTHONPATH=%COMFYUI_DIR%;%PYTHONPATH%

echo Clearing port 8188...
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":8188"') do taskkill /F /PID %%a 2>nul
timeout /t 1 >nul

cd /d "%COMFYUI_DIR%"
if not exist "main.py" (
    echo [ERROR] ComfyUI main.py not found in %COMFYUI_DIR%
    pause
    exit /b
)

"%PYTHON%" -u main.py --windows-standalone-build --port 8188 --listen 127.0.0.1 --reserve-vram 2 --disable-auto-launch

if %errorlevel% neq 0 (
    echo [ERROR] ComfyUI crashed with error code %errorlevel%
    pause
)
exit /b

:: ============================================================================
:: SUBROUTINE: FEDDA HUB (NEXT.JS)
:: ============================================================================
:launch_fedda_hub
cd /d "%~dp0"
cd ..
set "REPO_ROOT=%CD%"
set "NODE_EXE=%REPO_ROOT%\node_embeded\node.exe"
set "NPM_CMD=%REPO_ROOT%\node_embeded\npm.cmd"
:: Add portable Node/Git to path
set "PATH=%REPO_ROOT%\node_embeded;%REPO_ROOT%\git_embeded\cmd;%PATH%"

echo Clearing port 3000...
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":3000"') do taskkill /F /PID %%a 2>nul
timeout /t 1 >nul

:: Next.js app is in Root
if not exist ".env.local" (
    echo # Fedda Hub Config > .env.local
)

:: First time setup check (check if node_modules exists in root)
if not exist "node_modules" (
    echo [INFO] First run detected. Installing dependencies...
    call "%NPM_CMD%" install --legacy-peer-deps
    echo [INFO] Initializing Database...
    call "%NPM_CMD%" run prisma:generate
    call "%NPM_CMD%" run prisma:push
)

echo Starting Next.js...
call "%NPM_CMD%" run dev

if %errorlevel% neq 0 (
    echo [ERROR] Fedda Hub crashed!
    pause
)
exit /b

:: ============================================================================
:: SUBROUTINE: BROWSER WAITER
:: ============================================================================
:launch_browser
echo Waiting for Fedda Hub (localhost:3000)...
timeout /t 8 >nul
echo Launching...
start "" http://localhost:3000
exit /b
