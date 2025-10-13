@echo off
echo ========================================
echo Firebase Integration Test Runner
echo ========================================
echo.
echo IMPORTANT: Make sure Firebase emulators are running!
echo   cd lib/services
echo   firebase emulators:start
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul
echo.

REM Set PATH to avoid pwsh.exe issues
set PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;C:\src\flutter\bin

echo Checking available devices...
flutter devices
echo.

echo Running Firebase Integration Test on Windows...
echo.
flutter test integration_test\firebase_emulator_integration_test.dart -d windows --reporter=expanded

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ All Firebase Integration Tests Passed!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo ❌ Firebase Integration Tests Failed
    echo ========================================
    echo.
    echo Common issues:
    echo   1. Firebase emulators not running
    echo   2. Windows desktop not enabled: flutter config --enable-windows-desktop
    echo   3. Dependencies not installed: flutter pub get
    echo.
)

pause
