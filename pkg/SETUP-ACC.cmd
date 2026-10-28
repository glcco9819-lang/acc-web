@echo off
rem SETUP-ACC — creating acc database if missing (needs sa)
title YFG ACC-WEB — Database Setup
cd /d "%~dp0"
set /p SAPASS=Enter SA password: 
set SQLCMD=node\node.exe setup.js
set PORT=
"node\node.exe" setup.js
pause
