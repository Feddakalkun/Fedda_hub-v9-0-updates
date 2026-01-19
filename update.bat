@echo off
REM Wrapper script - calls installer/update.bat
cd /d "%~dp0installer"
call update.bat
pause
