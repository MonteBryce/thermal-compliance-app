@echo off
REM Set PATH to only include essential directories, avoiding pwsh.exe
set PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;C:\src\flutter\bin

REM Default test file
set TEST_FILE=%1
if "%TEST_FILE%"=="" set TEST_FILE=integration_test/firebase_emulator_integration_test.dart

REM Default device (windows for desktop)
set DEVICE=%2
if "%DEVICE%"=="" set DEVICE=windows

echo ========================================
echo Running Integration Test
echo ========================================
echo Test File: %TEST_FILE%
echo Device: %DEVICE%
echo.

flutter test %TEST_FILE% -d %DEVICE%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Test Passed Successfully!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Test Failed!
    echo ========================================
    exit /b %ERRORLEVEL%
)