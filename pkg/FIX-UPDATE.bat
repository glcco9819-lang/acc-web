@echo off
rem YFG ACC-WEB — نصب قطعی آپدیت معلق
rem جای‌گذاری: کنار START-ACC.bat (در پوشهٔ اصلی ACCWeb)
chcp 65001 >nul
title YFG ACC-WEB — نصب آپدیت معلق
cd /d "%~dp0"
echo ==============================================
echo   YFG ACC-WEB — نصب قطعی آپدیت معلق
echo ==============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix-update.ps1"
echo.
if exist "app\UPDATE.flag" (
  echo ----------------------------------------------
  echo   نصب ناموفق بود — از این پنجره تصویر بگیرید
  echo   و برای پشتیبانی بفرستید.
  echo ----------------------------------------------
) else (
  echo نصب موفق — راه‌اندازی سرویس...
  start "" "%~dp0START-ACC.bat"
)
echo.
pause
