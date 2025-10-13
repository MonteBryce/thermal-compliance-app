# Fix PowerShell Core Module Issue

## Problem Identified

Your PowerShell 7.5.3 is running from **Downloads folder** instead of being properly installed:
```
C:\Users\bryce.montemayor\Downloads\PowerShell-7.5.3-win-x64\pwsh.exe
```

This causes the error:
```
Cannot find the built-in module 'Microsoft.PowerShell.Utility' that is compatible with the 'Core' edition
```

## Root Cause

PowerShell Core modules are missing because:
1. PowerShell is extracted but **not properly installed**
2. The extracted archive doesn't include the required built-in modules folder
3. The `$PSHOME` path doesn't contain the Modules directory structure

## Solution Options

### Option 1: Proper Installation (Recommended)

**Step 1: Download PowerShell installer**
1. Go to: https://github.com/microsoft/PowerShell/releases/latest
2. Download: `PowerShell-7.5.3-win-x64.msi` (NOT the zip file)

**Step 2: Install PowerShell**
```cmd
REM Run the MSI installer
PowerShell-7.5.3-win-x64.msi
```

**Step 3: Verify installation**
```cmd
pwsh -Command "$PSVersionTable"
pwsh -Command "Get-Module -ListAvailable"
```

**Step 4: Update PATH (if needed)**
The proper installation path should be:
```
C:\Program Files\PowerShell\7\pwsh.exe
```

### Option 2: Continue Using Batch Files (Current Workaround)

If you don't want to reinstall PowerShell, **continue using the batch files** we created:
- `run_flutter.bat` - Run Flutter app
- `test_firebase.bat` - Run integration tests
- `enable_windows_desktop.bat` - Enable Windows desktop
- `start_firebase_emulators.bat` - Start Firebase emulators

These batch files bypass PowerShell by setting:
```batch
set PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;C:\src\flutter\bin
```

### Option 3: Use Windows PowerShell Instead

Use the older Windows PowerShell 5.1 (already on your system):
```cmd
REM Instead of: pwsh
REM Use: powershell

powershell -Command "flutter --version"
```

## Recommended Action Plan

### Quick Fix (5 minutes)
**Continue using batch files** - They work perfectly and avoid all PowerShell issues.

### Permanent Fix (10 minutes)
1. **Uninstall/Remove** the extracted PowerShell from Downloads folder
2. **Download MSI installer** from GitHub releases
3. **Install properly** to Program Files
4. **Verify** modules are available
5. **Update Flutter** to use the correct PowerShell

## Verify Fix

After proper installation, test:

```cmd
pwsh -Command "Get-Module -ListAvailable Microsoft.PowerShell.Utility"
pwsh -Command "flutter --version"
```

Should see modules listed without errors.

## Impact on Flutter

### Current State
- Flutter tries to use `pwsh.exe` from Downloads folder
- Fails because modules are missing
- Falls back with errors

### After Fix
- Flutter will use properly installed PowerShell 7
- All modules available
- No more "Cannot find built-in module" errors
- Can run Flutter commands from any PowerShell prompt

## Alternative: Remove PowerShell 7 from PATH

If you prefer to use Windows PowerShell 5.1 (built-in):

**Step 1: Remove Downloads PowerShell from PATH**
```cmd
REM Open System Environment Variables
SystemPropertiesAdvanced.exe
```

**Step 2: Edit PATH variable**
- Remove: `C:\Users\bryce.montemayor\Downloads\PowerShell-7.5.3-win-x64`
- Keep: `C:\Windows\System32\WindowsPowerShell\v1.0`

**Step 3: Restart terminal and test**
```cmd
pwsh --version
REM Should NOT find PowerShell 7

powershell -Version
REM Should show Windows PowerShell 5.1
```

## Summary

**Immediate Solution:** ✅ Use the batch files we created
**Permanent Fix:** 📥 Download and install PowerShell MSI properly
**Alternative:** 🔄 Use Windows PowerShell 5.1 instead

Choose based on your preference - all options work fine!
