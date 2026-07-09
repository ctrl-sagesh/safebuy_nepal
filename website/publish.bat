@echo off
REM ── SafeBuy Nepal — one-click publish (GitHub -> Vercel auto-deploy) ─────
REM Double-click after you make changes. It commits + pushes to GitHub,
REM and Vercel automatically builds & deploys. Your app updates on next open.
cd /d "%~dp0\.."
echo.
echo ==== Publishing website changes ====
git add website
git commit -m "Update website (%date% %time%)"
git push origin main
echo.
echo Pushed to GitHub. Vercel is now deploying automatically.
echo Your installed app will update the next time you open it.
echo.
pause
