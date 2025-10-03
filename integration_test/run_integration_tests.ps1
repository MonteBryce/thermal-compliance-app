#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Flutter Integration Test Runner for Windows
    
.DESCRIPTION
    Runs Flutter integration tests with proper setup and error handling
    
.PARAMETER Device
    Target device: chrome, edge, windows, or device ID (default: chrome)
    
.PARAMETER TestFile
    Specific test file to run (default: integration_test/app_smoke_test.dart)
    
.PARAMETER Verbose
    Enable verbose output
    
.PARAMETER ListDevices
    List available Flutter devices
    
.EXAMPLE
    .\run_integration_tests.ps1 -Device chrome
    
.EXAMPLE
    .\run_integration_tests.ps1 -Device chrome -TestFile integration_test/app_smoke_test.dart -Verbose
#>

param(
    [string]$Device = 'chrome',
    [string]$TestFile = 'integration_test/app_smoke_test.dart',
    [switch]$Verbose,
    [switch]$ListDevices
)

# Colors for output
$Red = [System.ConsoleColor]::Red
$Green = [System.ConsoleColor]::Green
$Yellow = [System.ConsoleColor]::Yellow
$Blue = [System.ConsoleColor]::Blue

function Write-ColorOutput {
    param([string]$Message, [System.ConsoleColor]$Color = [System.ConsoleColor]::White)
    Write-Host $Message -ForegroundColor $Color
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "========================================" $Blue
    Write-ColorOutput " $Title" $Blue
    Write-ColorOutput "========================================" $Blue
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" $Green
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠️ $Message" $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" $Red
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput $Message $Blue
}

function Show-Usage {
    Write-ColorOutput "Flutter Integration Test Runner" $Blue
    Write-Host ""
    Write-Host "Usage: .\run_integration_tests.ps1 [parameters]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -Device     : Target device (chrome, edge, windows, or device ID)"
    Write-Host "  -TestFile   : Specific test file to run"
    Write-Host "  -Verbose    : Enable verbose output"
    Write-Host "  -ListDevices: List available Flutter devices"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\run_integration_tests.ps1 -Device chrome"
    Write-Host "  .\run_integration_tests.ps1 -Device chrome -TestFile integration_test/app_smoke_test.dart"
    Write-Host "  .\run_integration_tests.ps1 -Verbose"
}

function Test-Prerequisites {
    Write-Section "Checking Prerequisites"
    
    $errors = @()
    
    # Check Flutter
    try {
        $flutterVersion = flutter --version 2>$null | Select-String "Flutter" | Select-Object -First 1
        Write-Success "Flutter: $($flutterVersion.Line)"
    } catch {
        $errors += "Flutter CLI not found"
        Write-Error "Flutter CLI not found. Please install Flutter SDK."
    }
    
    # Check if pubspec.yaml exists
    if (-not (Test-Path "pubspec.yaml")) {
        $errors += "pubspec.yaml not found"
        Write-Error "pubspec.yaml not found. Please run from Flutter project root."
    }
    
    # Check integration_test dependency
    $pubspecContent = Get-Content "pubspec.yaml" -Raw
    if ($pubspecContent -notmatch "integration_test:") {
        Write-Warning "integration_test package not found in pubspec.yaml"
        Write-Info "Adding integration_test to dev_dependencies..."
        
        # Add integration_test to dev_dependencies
        $pubspecLines = Get-Content "pubspec.yaml"
        $newPubspec = @()
        $devDepsSectionFound = $false
        
        foreach ($line in $pubspecLines) {
            $newPubspec += $line
            if ($line.Trim() -eq "dev_dependencies:") {
                $newPubspec += "  integration_test:"
                $newPubspec += "    sdk: flutter"
                $devDepsSectionFound = $true
            }
        }
        
        if ($devDepsSectionFound) {
            $newPubspec | Set-Content "pubspec.yaml"
            Write-Success "Added integration_test to pubspec.yaml"
        }
    }
    
    # Get dependencies
    Write-Info "Getting Flutter dependencies..."
    try {
        flutter pub get | Out-Null
        Write-Success "Dependencies resolved"
    } catch {
        $errors += "Failed to get dependencies"
        Write-Error "Failed to get Flutter dependencies"
    }
    
    if ($errors.Count -gt 0) {
        Write-Error "Prerequisites check failed:"
        $errors | ForEach-Object { Write-Error "  - $_" }
        exit 1
    }
    
    Write-Success "Prerequisites satisfied"
}

function Get-FlutterDevices {
    Write-Section "Available Flutter Devices"
    try {
        flutter devices
    } catch {
        Write-Error "Failed to list Flutter devices"
        exit 1
    }
}

function Test-Device {
    param([string]$DeviceName)
    
    # Common device patterns
    $webDevices = @('chrome', 'edge', 'firefox', 'safari')
    $desktopDevices = @('windows', 'macos', 'linux')
    
    if ($webDevices -contains $DeviceName) {
        Write-Info "Using web browser: $DeviceName"
        return $true
    }
    
    if ($desktopDevices -contains $DeviceName) {
        Write-Info "Using desktop platform: $DeviceName"
        return $true
    }
    
    # Check if it's a valid device ID
    try {
        $devices = flutter devices 2>$null
        if ($devices -match $DeviceName) {
            Write-Info "Using device: $DeviceName"
            return $true
        } else {
            Write-Warning "Device '$DeviceName' not found."
            Write-Info "Available devices:"
            flutter devices
            return $false
        }
    } catch {
        Write-Warning "Could not verify device '$DeviceName'"
        return $false
    }
}

function Invoke-IntegrationTests {
    param([string]$DeviceName, [string]$TestFilePath, [bool]$VerboseOutput)
    
    Write-Section "Running Integration Tests"
    
    # Check if test file exists
    if (-not (Test-Path $TestFilePath)) {
        Write-Error "Test file not found: $TestFilePath"
        exit 1
    }
    
    Write-Info "Device: $DeviceName"
    Write-Info "Test file: $TestFilePath"
    
    # Prepare flutter test command
    $flutterArgs = @('test', $TestFilePath)
    
    # Add device selection
    if ($DeviceName -ne 'default') {
        $flutterArgs += '-d'
        $flutterArgs += $DeviceName
    }
    
    # Add verbose flag if requested
    if ($VerboseOutput) {
        $flutterArgs += '--verbose'
    }
    
    # Add reporter for better output
    $flutterArgs += '--reporter'
    $flutterArgs += 'expanded'
    
    $commandString = "flutter " + ($flutterArgs -join ' ')
    Write-Info "Running command: $commandString"
    Write-Host ""
    
    # Run the tests
    try {
        $process = Start-Process -FilePath "flutter" -ArgumentList $flutterArgs -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Success "Integration tests completed successfully!"
            return $true
        } else {
            Write-Error "Integration tests failed with exit code: $($process.ExitCode)"
            return $false
        }
    } catch {
        Write-Error "Failed to run integration tests: $_"
        return $false
    }
}

function Invoke-Cleanup {
    Write-Section "Cleanup"
    
    # Clean Flutter build cache if needed
    if (Test-Path "build") {
        Write-Info "Cleaning build artifacts..."
        try {
            flutter clean | Out-Null
            Write-Success "Build artifacts cleaned"
        } catch {
            Write-Warning "Failed to clean build artifacts"
        }
    }
    
    Write-Success "Cleanup completed"
}

# Main execution
function Main {
    # Handle list devices flag
    if ($ListDevices) {
        Get-FlutterDevices
        exit 0
    }
    
    Write-Info "Flutter Integration Test Runner"
    Write-Info "Device: $Device | Test: $TestFile | Verbose: $Verbose"
    
    # Run checks and tests
    Test-Prerequisites
    
    if (-not (Test-Device $Device)) {
        Write-Error "Invalid device specified: $Device"
        exit 1
    }
    
    try {
        if (Invoke-IntegrationTests $Device $TestFile $Verbose) {
            Write-Success "All tests passed! 🎉"
            exit 0
        } else {
            Write-Error "Some tests failed 😞"
            exit 1
        }
    }
    finally {
        Invoke-Cleanup
    }
}

# Run main function
Main