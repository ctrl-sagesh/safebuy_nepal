@echo off
REM ── SafeBuy Nepal — automatic watch-and-deploy ──────────────────────────
REM Double-click to start. Leave the window open while you work.
REM Every time you save a change, it auto-publishes to Vercel a few seconds later.
cd /d "%~dp0"
node auto-deploy.js
pause
