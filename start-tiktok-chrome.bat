@echo off
REM === TikTok scrape Chrome launcher v2 ===
REM IMPORTANT: keep this file CRLF + ASCII only (cmd.exe misparses LF/UTF-8 batches)
REM Auto-detects chrome.exe; asks ONCE if missing; remembers path in chrome-path.txt
setlocal EnableExtensions

set "PROFILE=%USERPROFILE%\WorkBuddy\tiktok-chrome"
set "BATDIR=%~dp0"
set "CHROME="

if not exist "%PROFILE%" mkdir "%PROFILE%"

netstat -ano | findstr ":9223 " | findstr "LISTENING" >nul
if %errorlevel%==0 (
  echo [INFO] TikTok Chrome already running on port 9223. Nothing to do.
  echo To restart: close that Chrome window first, then run this file again.
  >nul 2>&1 timeout /t 4
  exit /b 0
)

if exist "%BATDIR%chrome-path.txt" set /p CHROME_SAVED=<"%BATDIR%chrome-path.txt"
if defined CHROME_SAVED if exist "%CHROME_SAVED%" set "CHROME=%CHROME_SAVED%"
if defined CHROME goto :launch

if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME=%LocalAppData%\Google\Chrome\Application\chrome.exe"
if defined CHROME goto :launch

for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" /ve 2^>nul') do set "REGVAL=%%B"
if not defined REGVAL for /f "tokens=2,*" %%A in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" /ve 2^>nul') do set "REGVAL=%%B"
if defined REGVAL if exist "%REGVAL%" set "CHROME=%REGVAL%"
if defined CHROME goto :launch

REM ponytail: quotes stripped on a separate top-level line -- inside parens,
REM %CAND% expands at parse time (empty) before `set CAND=` ever runs.
if defined REGVAL set CAND=%REGVAL:"=%
if defined CAND if exist "%CAND%" set "CHROME=%CAND%"
if defined CHROME goto :launch

echo [!] Google Chrome was not found on this machine.
echo     Enter the FULL PATH of chrome.exe below, then press Enter.
echo     Example: C:\Program Files\Google\Chrome\Application\chrome.exe
echo     Tip: you can also just DRAG chrome.exe into this window and press Enter.
echo     The path is saved next to this launcher (chrome-path.txt), asked only once.
echo.
set /p "CHROME_INPUT=chrome.exe full path: "
if "%CHROME_INPUT%"=="" goto :giveup
set "CHROME=%CHROME_INPUT%"
set CHROME=%CHROME:"=%
>"%BATDIR%chrome-path.txt" echo %CHROME%
echo [OK] Path saved. Next launches skip this question.
goto :launch

:launch
echo Starting TikTok scrape Chrome...
start "" "%CHROME%" --remote-debugging-port=9223 --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check --restore-last-session=false --window-size=1280,800 "https://www.tiktok.com/"
echo.
echo [OK] Started (port 9223, independent profile).
echo First time: please log in TikTok once inside this new Chrome window,
echo then just keep that window open. Claude connects automatically.
>nul 2>&1 timeout /t 5
exit /b 0

:giveup
echo [X] No path entered. Exiting.
>nul 2>&1 timeout /t 5
exit /b 1
