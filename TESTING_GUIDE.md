# E2E Testing Guide - Thermal Compliance App

## Overview
This guide helps you run end-to-end integration tests for the Thermal Compliance App.

## Prerequisites

### 1. PowerShell Issue Workaround
Your system has a PowerShell Core issue. **Use the provided batch files** instead of running Flutter commands directly.

### 2. Required Software

#### Node.js & Firebase CLI
**Check if installed:**
```cmd
node --version
firebase --version
```

**If not installed:**
1. Download Node.js: https://nodejs.org
2. Install Firebase CLI:
   ```cmd
   npm install -g firebase-tools
   ```
3. Login to Firebase:
   ```cmd
   firebase login
   ```

#### Flutter Windows Desktop Support
**Enable using the batch file:**
```cmd
enable_windows_desktop.bat
```

## Running Firebase Integration Tests

### Step 1: Start Firebase Emulators
**Open Terminal 1:**
```cmd
start_firebase_emulators.bat
```

This will start:
- 🔥 **Auth Emulator** on http://localhost:9099
- 📊 **Firestore Emulator** on http://localhost:8080
- 🖥️ **Emulator UI** on http://localhost:4000

Keep this terminal open while testing!

### Step 2: Run Integration Tests
**Open Terminal 2:**
```cmd
test_firebase.bat
```

This runs all Firebase integration tests including:
- ✅ Authentication flow with emulator
- ✅ Firestore data operations
- ✅ Thermal log entry with persistence
- ✅ Offline-to-online sync
- ✅ Multi-user conflict resolution
- ✅ Data validation and error handling

## Test Files

### Integration Tests
- **`integration_test/firebase_emulator_integration_test.dart`** - Firebase-specific tests
- **`integration_test/user_story_integration_test.dart`** - User story scenarios
- **`integration_test/app_smoke_test.dart`** - Basic smoke tests

### Helper Files
- **`integration_test/test_helpers.dart`** - Testing utilities
- **`integration_test/test_config.dart`** - Test configuration

## Batch Scripts Reference

| Script | Purpose |
|--------|---------|
| `test_firebase.bat` | Run Firebase integration tests |
| `start_firebase_emulators.bat` | Start Firebase emulators |
| `enable_windows_desktop.bat` | Enable Windows desktop support |
| `run_flutter.bat` | Run Flutter app (bypasses PowerShell issues) |
| `list_devices.bat` | List available Flutter devices |

## Troubleshooting

### Firebase CLI Not Found
```cmd
npm install -g firebase-tools
firebase login
```

### Windows Desktop Not Enabled
```cmd
enable_windows_desktop.bat
```

### PowerShell Errors
**Don't use PowerShell directly!** Use the provided `.bat` files instead.

### Web Device Not Supported
Integration tests require **Windows desktop**, not Chrome/Edge.

### Port Already in Use
If emulator ports are taken:
```cmd
netstat -ano | findstr "8080 9099 4000"
taskkill /PID <PID_NUMBER> /F
```

## Manual Test Commands

If you need to run tests manually (using cmd.exe, not PowerShell):

```cmd
REM Set correct PATH
set PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;C:\src\flutter\bin

REM Run specific test
flutter test integration_test\firebase_emulator_integration_test.dart -d windows

REM Run with verbose output
flutter test integration_test\firebase_emulator_integration_test.dart -d windows --verbose

REM Run all integration tests
flutter test integration_test -d windows
```

## Test Environment

### Emulator Configuration
The Firebase emulators are configured in `lib/services/firebase.json`:
- Auth: Port 9099
- Firestore: Port 8080
- UI: Port 4000

### Test Data Seeding
Tests automatically seed test data via `FirebaseEmulatorService.seedTestData()`:
- 2 Test Projects (Alpha & Beta)
- Sample thermal logs
- Test entries with readings

## CI/CD Integration

For automated testing in CI/CD pipelines, see the shell scripts:
- `integration_test/run_integration_tests.sh` (Unix/Linux/Mac)
- `integration_test/run_integration_tests.ps1` (PowerShell - if your environment supports it)

## Next Steps

1. ✅ Install Node.js and Firebase CLI (if needed)
2. ✅ Enable Windows desktop support
3. ✅ Start Firebase emulators
4. ✅ Run Firebase integration tests
5. Expand test coverage as needed

## Questions?

Check the integration test files for examples:
- `integration_test/firebase_emulator_integration_test.dart` - See test implementation
- `integration_test/test_helpers.dart` - Understand helper utilities
