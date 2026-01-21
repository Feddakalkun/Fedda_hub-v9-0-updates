@echo off
setlocal EnableDelayedExpansion
title Fedda Hub - Quick Push to GitHub
cd /d "%~dp0"

echo ============================================================================
echo   FEDDA HUB - QUICK PUSH TO GITHUB
echo ============================================================================
echo.
echo Repository: https://github.com/Feddakalkun/Fedda_hub-v9-0-updates
echo Branch: main
echo.

:: Check if there are changes
git status --short > nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Not a git repository or git not found!
    echo Please make sure you're in the Fedda Hub directory.
    pause
    exit /b 1
)

:: Show current status
echo ========== Current Changes ==========
git status --short
echo =====================================
echo.

:: Check if there are any changes
git diff-index --quiet HEAD --
if %errorlevel% equ 0 (
    echo [INFO] No changes to commit.
    echo.
    pause
    exit /b 0
)

:: Prompt for commit message
echo Enter commit message (or press Enter for default message):
set /p COMMIT_MSG="Commit message: "

if "%COMMIT_MSG%"=="" (
    :: Generate default commit message with timestamp
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
    set TIMESTAMP=!datetime:~0,4!-!datetime:~4,2!-!datetime:~6,2! !datetime:~8,2!:!datetime:~10,2!
    set COMMIT_MSG=Update: Changes from !TIMESTAMP!
)

echo.
echo ========== Staging Changes ==========
:: Add all tracked files and new files in important directories
git add -A

echo.
echo ========== Files to be committed ==========
git diff --cached --name-status
echo ============================================
echo.

:: Confirm before pushing
echo Commit message: %COMMIT_MSG%
echo.
set /p CONFIRM="Push these changes to GitHub? (y/N): "

if /i not "%CONFIRM%"=="y" (
    echo.
    echo [CANCELLED] Changes not pushed.
    echo Use 'git status' to see pending changes.
    pause
    exit /b 0
)

:: Commit and push
echo.
echo ========== Committing ==========
git commit -m "%COMMIT_MSG%"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Commit failed! Check the error above.
    pause
    exit /b 1
)

echo.
echo ========== Pushing to GitHub ==========
git push origin main

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Push failed! Possible reasons:
    echo   - No internet connection
    echo   - Authentication required (check credentials)
    echo   - Remote repository issues
    echo.
    echo You can try manually with: git push origin main
    pause
    exit /b 1
)

echo.
echo ============================================================================
echo   SUCCESS! Changes pushed to GitHub
echo ============================================================================
echo.
echo View your changes at:
echo https://github.com/Feddakalkun/Fedda_hub-v9-0-updates
echo.
pause
