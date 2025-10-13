@echo off
echo ========================================
echo PowerShell 7 Installation via WinGet
echo ========================================
echo.
echo This is the EASIEST method to install PowerShell properly!
echo.
echo Checking if winget is available...
where winget >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ WinGet not found
    echo.
    echo Please use install_powershell.bat for manual installation instead.
    pause
    exit /b 1
)

echo ✅ WinGet found
echo.
echo Installing PowerShell 7 via WinGet...
echo This will:
echo   - Download PowerShell 7.5 from Microsoft
echo   - Install it to Program Files
echo   - Add it to PATH automatically
echo   - Include all required modules
echo.
pause

winget install --id Microsoft.Powershell --source winget

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ PowerShell installed successfully!
    echo ========================================
    echo.
    echo Now cleaning up old version from Downloads...

    if exist "C:\Users\bryce.montemayor\Downloads\PowerShell-7.5.3-win-x64\" (
        echo Removing old extracted PowerShell...
        rd /s /q "C:\Users\bryce.montemayor\Downloads\PowerShell-7.5.3-win-x64\"
        echo ✅ Old version removed
    )

    echo.
    echo ========================================
    echo Next Steps:
    echo ========================================
    echo 1. CLOSE this terminal
    echo 2. Open a NEW terminal
    echo 3. Run: verify_powershell.bat
    echo.
) else (
    echo.
    echo ========================================
    echo ❌ Installation failed
    echo ========================================
    echo.
    echo Try: install_powershell.bat for manual installation
    echo.
)

pause
