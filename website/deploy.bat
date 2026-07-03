@echo off
REM ── SafeBuy Nepal — one-click deploy to Vercel ──────────────────────────
REM Double-click this file to publish your latest changes.
cd /d "%~dp0"
echo.
echo ==== Deploying SafeBuy Nepal to production ====
echo.
call vercel --prod --yes
echo.
echo Done. Open the app on your phone - it updates on the next launch.
echo.
pause
