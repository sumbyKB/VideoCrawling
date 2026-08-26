@echo off
REM === TikTok scrape Chrome launcher ===
REM Independent profile + debug port 9223, no auth popup
REM First time: login TikTok once in the new window
REM Repo: tiktok-creator-scan

set CHROME=C:\Users\%USERNAME%\AppData\Local\Google\Chrome\Application\chrome.exe
set PROFILE=C:\Users\%USERNAME%\WorkBuddy\tiktok-chrome

if not exist "%PROFILE%" mkdir "%PROFILE%"

netstat -ano | findstr ":9223 " | findstr "LISTENING" >nul
if %errorlevel%==0 (
  echo [INFO] TikTok Chrome is already running on port 9223
  echo To restart: close that Chrome window first, then double-click this file again
  timeout /t 3 >nul
  exit /b
)

echo Starting TikTok scrape Chrome...
start "" "%CHROME%" --remote-debugging-port=9223 --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check --restore-last-session=false --window-size=1280,800 "https://www.tiktok.com/"
echo.
echo Started (port 9223, independent profile)
echo First time: please login TikTok once in the new Chrome window
echo After that, just keep this window open, Claude will connect automatically
echo.
timeout /t 5 >nul
