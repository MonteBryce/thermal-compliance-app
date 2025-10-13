@echo off
REM Enable Windows Desktop for Flutter (bypassing PowerShell issues)
set PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;C:\src\flutter\bin

echo ========================================
echo Enabling Flutter Windows Desktop
echo ========================================
echo.

flutter config --enable-windows-desktop

echo.
echo Generating Windows project files...
flutter create --platforms=windows .

echo.
echo ========================================
echo Done!
echo ========================================
pause
