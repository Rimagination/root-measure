@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Invoke-Rv.ps1" %*
exit /b %ERRORLEVEL%
