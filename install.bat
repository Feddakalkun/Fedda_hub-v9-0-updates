@echo off
REM Wrapper script - calls installer/install.bat
cd /d "%~dp0installer"
call install.bat
pause
