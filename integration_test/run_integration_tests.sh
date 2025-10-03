#!/bin/bash

# Flutter Integration Test Runner
# Usage: ./run_integration_tests.sh [device] [test_file]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEVICE="${1:-chrome}"
TEST_FILE="${2:-integration_test/app_smoke_test.dart}"
VERBOSE="${VERBOSE:-false}"

log_info() {
    echo -e "${BLUE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Show usage
show_usage() {
    echo "Flutter Integration Test Runner"
    echo ""
    echo "Usage: $0 [DEVICE] [TEST_FILE]"
    echo ""
    echo "Parameters:"
    echo "  DEVICE    : Target device (chrome, edge, macos, windows, linux, or device ID)"
    echo "  TEST_FILE : Specific test file to run (default: integration_test/app_smoke_test.dart)"
    echo ""
    echo "Environment Variables:"
    echo "  VERBOSE   : Set to 'true' for verbose output"
    echo ""
    echo "Examples:"
    echo "  $0 chrome"
    echo "  $0 chrome integration_test/app_smoke_test.dart"
    echo "  VERBOSE=true $0 chrome"
    echo "  $0 macos integration_test/specific_test.dart"
}

# Check prerequisites
check_prerequisites() {
    log_section "Checking Prerequisites"
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter CLI not found. Please install Flutter SDK."
        exit 1
    fi
    
    local flutter_version=$(flutter --version | head -n 1)
    log_success "Flutter: $flutter_version"
    
    # Check if integration_test is available
    if ! flutter pub deps | grep -q "integration_test"; then
        log_warning "integration_test package not found in dependencies"
        log_info "Adding integration_test to pubspec.yaml..."
        
        # Check if integration_test is already in dev_dependencies
        if ! grep -q "integration_test:" pubspec.yaml; then
            # Add integration_test to dev_dependencies
            sed -i '/dev_dependencies:/a\  integration_test:\n    sdk: flutter' pubspec.yaml
        fi
    fi
    
    # Get dependencies
    log_info "Getting Flutter dependencies..."
    flutter pub get
    
    log_success "Prerequisites satisfied"
}

# List available devices
list_devices() {
    log_section "Available Devices"
    flutter devices
}

# Validate target device
validate_device() {
    local device="$1"
    
    case $device in
        chrome|edge|firefox|safari)
            log_info "Using web browser: $device"
            return 0
            ;;
        macos|windows|linux)
            log_info "Using desktop platform: $device"
            return 0
            ;;
        *)
            # Check if it's a valid device ID
            if flutter devices | grep -q "$device"; then
                log_info "Using device: $device"
                return 0
            else
                log_warning "Device '$device' not found. Available devices:"
                flutter devices
                return 1
            fi
            ;;
    esac
}

# Run integration tests
run_integration_tests() {
    local device="$1"
    local test_file="$2"
    
    log_section "Running Integration Tests"
    
    # Check if test file exists
    if [ ! -f "$test_file" ]; then
        log_error "Test file not found: $test_file"
        exit 1
    fi
    
    log_info "Device: $device"
    log_info "Test file: $test_file"
    
    # Prepare flutter test command
    local flutter_cmd="flutter test $test_file"
    
    # Add device selection
    if [ "$device" != "default" ]; then
        flutter_cmd="$flutter_cmd -d $device"
    fi
    
    # Add verbose flag if requested
    if [ "$VERBOSE" = "true" ]; then
        flutter_cmd="$flutter_cmd --verbose"
    fi
    
    # Add reporter for better output
    flutter_cmd="$flutter_cmd --reporter expanded"
    
    log_info "Running command: $flutter_cmd"
    echo ""
    
    # Run the tests
    if eval "$flutter_cmd"; then
        log_success "Integration tests completed successfully!"
        return 0
    else
        log_error "Integration tests failed!"
        return 1
    fi
}

# Clean up artifacts
cleanup() {
    log_section "Cleanup"
    
    # Clean Flutter build cache if needed
    if [ -d "build" ]; then
        log_info "Cleaning build artifacts..."
        flutter clean
    fi
    
    log_success "Cleanup completed"
}

# Main execution
main() {
    # Handle help flag
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    # Handle list devices flag
    if [ "$1" = "--list-devices" ]; then
        list_devices
        exit 0
    fi
    
    log_info "Flutter Integration Test Runner"
    log_info "Device: $DEVICE | Test: $TEST_FILE | Verbose: $VERBOSE"
    
    # Run checks and tests
    check_prerequisites
    
    if ! validate_device "$DEVICE"; then
        log_error "Invalid device specified: $DEVICE"
        exit 1
    fi
    
    if run_integration_tests "$DEVICE" "$TEST_FILE"; then
        log_success "All tests passed! 🎉"
        exit 0
    else
        log_error "Some tests failed 😞"
        exit 1
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"