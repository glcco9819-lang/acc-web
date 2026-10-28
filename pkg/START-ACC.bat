@echo off
rem YFG ACC-WEB Launcher — port 5031 + online update installer
title YFG ACC-WEB Server
cd /d "%~dp0"
:loop
  set PORT=5031
  echo ==============================================
  echo   YFG ACC-WEB  ^|  http://localhost:5031
  echo   DB: see app\db-config.json
  echo ==============================================
  "node\node.exe" app\server.js
  echo.
  echo Server exited. Checking for pending update...
  if exist "app\UPDATE.flag" (
    echo UPDATE.flag found - applying update...
    powershell -NoProfile -ExecutionPolicy Bypass -File "update.ps1"
  )
  timeout /t 2 /nobreak >nul
goto loop
