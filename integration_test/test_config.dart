/// Configuration and constants for integration tests
class TestConfig {
  
  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration longTimeout = Duration(minutes: 2);
  static const Duration animationTimeout = Duration(seconds: 3);
  
  // Delays
  static const Duration tapDelay = Duration(milliseconds: 500);
  static const Duration navigationDelay = Duration(seconds: 2);
  static const Duration dataEntryDelay = Duration(milliseconds: 300);
  static const Duration screenTransitionDelay = Duration(seconds: 1);
  
  // Test data
  static const String testProjectId = 'DEMO-2025-001';
  static const String testLogId = 'test-log-${timestamp}';
  static const String testOperatorId = 'TEST_OP_001';
  
  static String get timestamp => DateTime.now().millisecondsSinceEpoch.toString();
  
  // Screen identifiers
  static const Map<String, List<String>> screenIdentifiers = {
    'ProjectSelector': ['DEMO', 'Project', 'Select', 'Create'],
    'DailySummary': ['Daily', 'Summary', 'Progress', 'Complete'],
    'HourSelector': ['Hour', 'Grid', '00', '12', '24'],
    'HourlyEntry': ['Temperature', 'Inlet', 'Outlet', 'Save', 'Entry'],
    'ReviewEntries': ['Review', 'Entries', 'All', 'Complete'],
    'SystemMetrics': ['System', 'Metrics', 'Storage', 'Performance'],
  };
  
  // Test thermal data
  static const Map<String, dynamic> sampleThermalReading = {
    'hour': 12,
    'inletReading': 1200.0,
    'outletReading': 1250.0,
    'toInletReadingH2S': 5.5,
    'vaporInletFlowRateFPM': 150.0,
    'vaporInletFlowRateBBL': 25.0,
    'tankRefillFlowRate': 10.0,
    'combustionAirFlowRate': 200.0,
    'vacuumAtTankVaporOutlet': -2.5,
    'exhaustTemperature': 1300.0,
    'totalizer': 1234.5,
    'observations': 'Test entry - automated integration test',
    'operatorId': testOperatorId,
    'validated': false,
  };
  
  // Form field identifiers
  static const Map<String, String> formFields = {
    'inletTemperature': 'Inlet Temperature',
    'outletTemperature': 'Outlet Temperature',
    'h2sReading': 'H2S Reading',
    'flowRate': 'Flow Rate',
    'pressure': 'Pressure',
    'observations': 'Observations',
  };
  
  // Navigation paths
  static const Map<String, List<String>> navigationPaths = {
    'projectToDailySummary': ['Demo Project', 'Summary'],
    'summaryToHourSelector': ['Hour Selector', 'Hours'],
    'hourSelectorToEntry': ['12', 'Hour 12'],
    'entryToReview': ['Review', 'Review All'],
    'anyToSystemMetrics': ['Settings', 'Metrics', 'System'],
  };
  
  // Expected elements per screen
  static const Map<String, List<String>> expectedElements = {
    'ProjectSelector': ['Card', 'ElevatedButton', 'Text'],
    'DailySummary': ['CircularProgressIndicator', 'Card', 'AppBar'],
    'HourSelector': ['GridView', 'GestureDetector', 'Container'],
    'HourlyEntry': ['TextFormField', 'ElevatedButton', 'Form'],
    'ReviewEntries': ['ListView', 'DataTable', 'Card'],
    'SystemMetrics': ['Card', 'Text', 'LinearProgressIndicator'],
  };
  
  // Test flags
  static const bool enableDebugOutput = true;
  static const bool skipSlowTests = false;
  static const bool enableScreenshots = true;
  static const bool enablePerformanceTesting = true;
  
  // Performance thresholds
  static const Duration maxStartupTime = Duration(seconds: 10);
  static const Duration maxNavigationTime = Duration(seconds: 5);
  static const Duration maxFormSubmissionTime = Duration(seconds: 3);
  
  // Error patterns to ignore (expected/acceptable errors)
  static const List<String> ignorableErrors = [
    'Firebase', 
    'Development mode',
    'Warning:',
    'flutter_web_plugins',
    'favicon.ico',
  ];
  
  // Critical error patterns that should fail tests
  static const List<String> criticalErrors = [
    'Exception:',
    'Error:',
    'Fatal:',
    'Unhandled',
    'RenderFlex overflow',
  ];
  
  // Test environment detection
  static bool get isRunningInCI => 
      const bool.fromEnvironment('CI') || 
      const bool.fromEnvironment('GITHUB_ACTIONS');
      
  static bool get isDebugMode => 
      const bool.fromEnvironment('flutter.debugMode', defaultValue: false);
      
  static bool get isProfileMode => 
      const bool.fromEnvironment('flutter.profileMode', defaultValue: false);
}

/// Test environment configuration
class TestEnvironment {
  static const String local = 'local';
  static const String ci = 'ci';
  static const String device = 'device';
  
  static String get current {
    if (TestConfig.isRunningInCI) return ci;
    // Add device detection logic here
    return local;
  }
  
  static Map<String, dynamic> get config {
    switch (current) {
      case ci:
        return {
          'enableScreenshots': false,
          'enableVerboseLogging': true,
          'maxRetries': 5,
          'timeout': TestConfig.longTimeout,
        };
      case device:
        return {
          'enableScreenshots': true,
          'enableVerboseLogging': false,
          'maxRetries': 3,
          'timeout': TestConfig.defaultTimeout,
        };
      case local:
      default:
        return {
          'enableScreenshots': TestConfig.enableScreenshots,
          'enableVerboseLogging': TestConfig.enableDebugOutput,
          'maxRetries': 2,
          'timeout': TestConfig.defaultTimeout,
        };
    }
  }
}