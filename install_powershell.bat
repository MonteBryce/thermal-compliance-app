@echo off
echo ========================================
echo PowerShell 7 Proper Installation Guide
echo ========================================
echo.
echo This script will help you install PowerShell 7 properly.
echo.
echo Step 1: Download PowerShell MSI Installer
echo ========================================
echo.
echo Opening download page in your browser...
echo Please download: PowerShell-7.5.3-win-x64.msi
echo.
start https://github.com/PowerShell/PowerShell/releases
echo.
echo Press any key after you've downloaded the MSI file...
pause > nul
echo.

echo Step 2: Locate the MSI installer
echo ========================================
echo.
echo Checking Downloads folder...

if exist "%USERPROFILE%\Downloads\PowerShell-7.5.3-win-x64.msi" (
    echo ✅ Found: PowerShell-7.5.3-win-x64.msi
    set MSI_PATH=%USERPROFILE%\Downloads\PowerShell-7.5.3-win-x64.msi
    goto :install
)

if exist "%USERPROFILE%\Downloads\PowerShell-*.msi" (
    echo ✅ Found PowerShell MSI installer
    for %%f in ("%USERPROFILE%\Downloads\PowerShell-*.msi") do set MSI_PATH=%%f
    goto :install
)

echo ❌ MSI installer not found in Downloads folder
echo.
echo Please download the MSI file and run this script again.
echo Or manually run: msiexec /i "path\to\PowerShell-7.5.3-win-x64.msi"
echo.
pause
exit /b 1

:install
echo.
echo Step 3: Install PowerShell
echo ========================================
echo.
echo Installing from: %MSI_PATH%
echo.
echo Note: This will open the installer. Follow the prompts:
echo   1. Click "Next"
echo   2. Accept the license agreement
echo   3. Choose "Add PowerShell to PATH"
echo   4. Click "Install"
echo.
pause

REM Run the MSI installer
msiexec /i "%MSI_PATH%"

echo.
echo Step 4: Clean up old PowerShell from Downloads
echo ========================================
echo.
echo After installation completes, we'll clean up the old extracted version.
echo.
echo Press any key to continue after the installer finishes...
pause > nul

REM Remove the old extracted version from Downloads
if exist "C:\Users\bryce.montemayor\Downloads\PowerShell-7.5.3-win-x64\" (
    echo Removing old extracted PowerShell from Downloads...
    rd /s /q "C:\Users\bryce.montemayor\Downloads\PowerShell-7.5.3-win-x64\"
    echo ✅ Old version removed
)

echo.
echo Step 5: Verify Installation
echo ========================================
echo.
echo Close this terminal and open a NEW PowerShell window.
echo Then run these commands to verify:
echo.
echo   pwsh -Command "$PSVersionTable"
echo   pwsh -Command "Get-Module -ListAvailable"
echo   flutter --version
echo.
echo If no errors appear, PowerShell is fixed! ✅
echo.
pause
