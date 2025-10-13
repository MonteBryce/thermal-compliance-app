@echo off
echo ========================================
echo PowerShell Installation Verification
echo ========================================
echo.

echo Checking PowerShell installation...
echo.

echo 1. Finding PowerShell executable:
where pwsh
echo.

echo 2. PowerShell version:
pwsh -Command "$PSVersionTable.PSVersion"
echo.

echo 3. PowerShell home directory:
pwsh -Command "$PSHOME"
echo.

echo 4. Checking for required modules:
pwsh -Command "Get-Module -ListAvailable Microsoft.PowerShell.Utility | Select-Object Name, Version"
pwsh -Command "Get-Module -ListAvailable Microsoft.PowerShell.Management | Select-Object Name, Version"
echo.

echo 5. Testing Flutter with PowerShell:
set PATH=C:\Windows\System32;C:\Windows;C:\Program Files\PowerShell\7;C:\src\flutter\bin
flutter --version
echo.

if %ERRORLEVEL% EQU 0 (
    echo ========================================
    echo ✅ PowerShell is properly installed!
    echo ========================================
) else (
    echo ========================================
    echo ❌ PowerShell has issues
    echo ========================================
)

echo.
pause
