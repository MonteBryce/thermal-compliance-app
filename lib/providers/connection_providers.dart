import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connection_service.dart';

/// Provider for the connection service singleton
final connectionServiceProvider = Provider<ConnectionService>((ref) {
  return ConnectionService();
});

/// Provider that streams connection state changes
final connectionStateProvider = StreamProvider<ConnectionState>((ref) {
  final connectionService = ref.watch(connectionServiceProvider);
  return connectionService.connectionStateStream;
});

/// Provider that streams data mode changes
final dataModeProvider = StreamProvider<DataMode>((ref) {
  final connectionService = ref.watch(connectionServiceProvider);
  return connectionService.dataModeStream;
});

/// Provider for current connection status (synchronous)
final currentConnectionStateProvider = Provider<ConnectionState>((ref) {
  final connectionService = ref.watch(connectionServiceProvider);
  return connectionService.connectionState;
});

/// Provider for current data mode (synchronous)
final currentDataModeProvider = Provider<DataMode>((ref) {
  final connectionService = ref.watch(connectionServiceProvider);
  return connectionService.dataMode;
});

/// Provider that indicates if we should use Firestore
final useFirestoreProvider = Provider<bool>((ref) {
  final dataMode = ref.watch(currentDataModeProvider);
  return dataMode == DataMode.firestore;
});

/// Provider that indicates if we should use Hive
final useHiveProvider = Provider<bool>((ref) {
  final dataMode = ref.watch(currentDataModeProvider);
  return dataMode == DataMode.hive;
});

/// Provider for connection status text
final connectionStatusTextProvider = Provider<String>((ref) {
  final connectionService = ref.watch(connectionServiceProvider);
  return connectionService.getConnectionStatusText();
});

/// Provider for connection status icon
final connectionStatusIconProvider = Provider<String>((ref) {
  final connectionService = ref.watch(connectionServiceProvider);
  return connectionService.getConnectionStatusIcon();
});