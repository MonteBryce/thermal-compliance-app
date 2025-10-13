@echo off
echo ========================================
echo Starting Firebase Emulators
echo ========================================
echo.
echo IMPORTANT: You need Firebase CLI installed!
echo If not installed, run: npm install -g firebase-tools
echo.
echo Checking for Firebase CLI...

where firebase >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Firebase CLI not found!
    echo.
    echo To install Firebase CLI:
    echo   1. Install Node.js from https://nodejs.org
    echo   2. Run: npm install -g firebase-tools
    echo   3. Run: firebase login
    echo.
    pause
    exit /b 1
)

echo ✅ Firebase CLI found
echo.
echo Starting emulators from lib/services directory...
cd lib\services

firebase emulators:start

pause
