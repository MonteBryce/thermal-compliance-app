import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Enum for connection states
enum ConnectionState {
  online,
  offline,
  poor,
  switching,
}

/// Enum for data storage modes
enum DataMode {
  firestore,  // Online mode - direct Firestore
  hive,       // Offline mode - local Hive storage
  hybrid,     // Smart mode - both with sync
}

/// Service that manages internet connection detection and data mode switching
class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Current state
  ConnectionState _connectionState = ConnectionState.offline;
  DataMode _dataMode = DataMode.hive; // Start in safe offline mode
  bool _manualOfflineMode = false;
  
  // Stream controllers
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  final _dataModeController = StreamController<DataMode>.broadcast();
  
  // Getters
  ConnectionState get connectionState => _connectionState;
  DataMode get dataMode => _dataMode;
  bool get isOnline => _connectionState == ConnectionState.online;
  bool get isOffline => _connectionState == ConnectionState.offline;
  bool get useFirestore => _dataMode == DataMode.firestore;
  bool get useHive => _dataMode == DataMode.hive;
  bool get isManualOfflineMode => _manualOfflineMode;
  
  // Streams
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<DataMode> get dataModeStream => _dataModeController.stream;
  
  /// Initialize the connection service
  Future<void> initialize() async {
    try {
      // Check initial connection
      final result = await _connectivity.checkConnectivity();
      await _handleConnectivityChange(result);
      
      // Listen for connection changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
        onError: (error) {
          debugPrint('Connection service error: $error');
          _updateConnectionState(ConnectionState.offline);
        },
      );
      
      debugPrint('ConnectionService initialized');
    } catch (e) {
      debugPrint('Failed to initialize ConnectionService: $e');
      _updateConnectionState(ConnectionState.offline);
    }
  }
  
  /// Handle connectivity changes
  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.none:
        await _setOfflineMode();
        break;
      case ConnectivityResult.mobile:
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
        await _testInternetConnection();
        break;
      default:
        await _setOfflineMode();
        break;
    }
  }
  
  /// Test actual internet connectivity (not just network connection)
  Future<void> _testInternetConnection() async {
    try {
      _updateConnectionState(ConnectionState.switching);
      
      // Test with a quick ping to Google DNS
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Test Firestore connectivity
        final firestoreReachable = await _testFirestoreConnection();
        if (firestoreReachable) {
          await _setOnlineMode();
        } else {
          await _setPoorConnectionMode();
        }
      } else {
        await _setOfflineMode();
      }
    } catch (e) {
      debugPrint('Internet connection test failed: $e');
      await _setOfflineMode();
    }
  }
  
  /// Test if Firestore is reachable
  Future<bool> _testFirestoreConnection() async {
    try {
      // Simple test - try to access Firestore
      // This is a placeholder - implement actual Firestore ping
      await Future.delayed(const Duration(milliseconds: 500));
      return true; // Assume success for now
    } catch (e) {
      debugPrint('Firestore connection test failed: $e');
      return false;
    }
  }
  
  /// Set online mode
  Future<void> _setOnlineMode() async {
    if (_manualOfflineMode) return; // Don't override manual mode
    
    _updateConnectionState(ConnectionState.online);
    _updateDataMode(DataMode.firestore);
    debugPrint('Switched to online mode (Firestore)');
  }
  
  /// Set offline mode
  Future<void> _setOfflineMode() async {
    _updateConnectionState(ConnectionState.offline);
    _updateDataMode(DataMode.hive);
    debugPrint('Switched to offline mode (Hive)');
  }
  
  /// Set poor connection mode
  Future<void> _setPoorConnectionMode() async {
    if (_manualOfflineMode) return;
    
    _updateConnectionState(ConnectionState.poor);
    _updateDataMode(DataMode.hive); // Use Hive for stability
    debugPrint('Poor connection - using offline mode (Hive)');
  }
  
  /// Manually force offline mode
  void setManualOfflineMode(bool enable) {
    _manualOfflineMode = enable;
    if (enable) {
      _updateConnectionState(ConnectionState.offline);
      _updateDataMode(DataMode.hive);
      debugPrint('Manual offline mode enabled');
    } else {
      // Re-check connection
      _testInternetConnection();
      debugPrint('Manual offline mode disabled - checking connection');
    }
  }
  
  /// Force a connection check
  Future<void> refreshConnection() async {
    _updateConnectionState(ConnectionState.switching);
    await _testInternetConnection();
  }
  
  /// Update connection state and notify listeners
  void _updateConnectionState(ConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _connectionStateController.add(newState);
    }
  }
  
  /// Update data mode and notify listeners
  void _updateDataMode(DataMode newMode) {
    if (_dataMode != newMode) {
      _dataMode = newMode;
      _dataModeController.add(newMode);
    }
  }
  
  /// Get connection status text for UI
  String getConnectionStatusText() {
    switch (_connectionState) {
      case ConnectionState.online:
        return 'Online';
      case ConnectionState.offline:
        return _manualOfflineMode ? 'Offline (Manual)' : 'Offline';
      case ConnectionState.poor:
        return 'Poor Connection';
      case ConnectionState.switching:
        return 'Checking...';
    }
  }
  
  /// Get connection status icon for UI
  String getConnectionStatusIcon() {
    switch (_connectionState) {
      case ConnectionState.online:
        return '📶';
      case ConnectionState.offline:
        return '📴';
      case ConnectionState.poor:
        return '⚠️';
      case ConnectionState.switching:
        return '🔄';
    }
  }
  
  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStateController.close();
    _dataModeController.close();
  }
}