@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "ROOT_MEASURE_CLI_ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%..\scripts\root-measure.ps1"
exit /b %ERRORLEVEL%

