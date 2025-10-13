import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/local_database_service.dart';
import '../services/connection_service.dart';
import '../models/hive_models.dart';
import '../models/thermal_reading.dart';
import '../utils/timestamp_utils.dart';
import 'connection_providers.dart';

/// Provider that manages hybrid data access - automatically switches between Firestore and Hive
/// based on connection state and data mode
class HybridDataProvider {
  final Ref ref;
  final FirebaseFirestore _firestore;

  HybridDataProvider(this.ref) : _firestore = FirebaseFirestore.instance;

  /// Get thermal readings for a specific day using hybrid approach
  Future<List<ThermalReading>> getThermalReadingsForDay({
    required String projectId,
    required String logDate,
  }) async {
    final useFirestore = ref.read(useFirestoreProvider);

    if (useFirestore) {
      try {
        return await _getFirestoreThermalReadings(projectId, logDate);
      } catch (e) {
        // Fallback to Hive if Firestore fails
        print('⚠️ Firestore failed, falling back to Hive: $e');
        return await _getHiveThermalReadings(projectId, logDate);
      }
    } else {
      return await _getHiveThermalReadings(projectId, logDate);
    }
  }

  /// Save thermal reading using hybrid approach
  Future<void> saveThermalReading({
    required String projectId,
    required String logDate,
    required ThermalReading reading,
  }) async {
    final useFirestore = ref.read(useFirestoreProvider);

    // Always save to Hive first for offline reliability
    await _saveToHive(projectId, logDate, reading);

    if (useFirestore) {
      try {
        await _saveToFirestore(projectId, logDate, reading);
        // Mark as synced in Hive
        await _markAsSynced(projectId, logDate, reading.hour);
      } catch (e) {
        // Mark for later sync if Firestore save fails
        print('⚠️ Firestore save failed, marking for sync: $e');
        await _markForSync(projectId, logDate, reading.hour);
      }
    } else {
      // Mark for later sync when offline
      await _markForSync(projectId, logDate, reading.hour);
    }
  }

  /// Get completed hours using hybrid approach
  Future<Set<int>> getCompletedHours({
    required String projectId,
    required String logDate,
  }) async {
    final useFirestore = ref.read(useFirestoreProvider);

    if (useFirestore) {
      try {
        return await _getFirestoreCompletedHours(projectId, logDate);
      } catch (e) {
        print('⚠️ Firestore failed, falling back to Hive: $e');
        return await _getHiveCompletedHours(projectId, logDate);
      }
    } else {
      return await _getHiveCompletedHours(projectId, logDate);
    }
  }

  /// Sync pending data from Hive to Firestore
  Future<void> syncPendingData() async {
    final useFirestore = ref.read(useFirestoreProvider);
    if (!useFirestore) return;

    try {
      final pendingItems =
          await LocalDatabaseService.getPendingSyncOperations();
      print('📤 Syncing ${pendingItems.length} pending items to Firestore');

      for (final item in pendingItems) {
        try {
          await _syncItemToFirestore(item);
          await LocalDatabaseService.updateSyncQueueEntry(item.id,
              remove: true);
          print('✅ Synced item: ${item.id}');
        } catch (e) {
          print('❌ Failed to sync item ${item.id}: $e');
          await LocalDatabaseService.updateSyncQueueEntry(item.id,
              error: e.toString());
        }
      }
    } catch (e) {
      print('❌ Sync operation failed: $e');
    }
  }

  // Private Firestore methods
  Future<List<ThermalReading>> _getFirestoreThermalReadings(
      String projectId, String logDate) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('thermal_logs')
        .doc(logDate)
        .collection('readings')
        .orderBy('hour')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ThermalReading(
        hour: data['hour'] ?? 0,
        timestamp:
            TimestampUtils.toDateTimeOrNow(data['timestamp']).toIso8601String(),
        inletReading: data['inletReading']?.toDouble(),
        outletReading: data['outletReading']?.toDouble(),
        toInletReadingH2S: data['toInletReadingH2S']?.toDouble(),
        lelInletReading: data['lelInletReading']?.toDouble(),
        vaporInletFlowRateFPM: data['vaporInletFlowRateFPM']?.toDouble(),
        vaporInletFlowRateBBL: data['vaporInletFlowRateBBL']?.toDouble(),
        tankRefillFlowRate: data['tankRefillFlowRate']?.toDouble(),
        combustionAirFlowRate: data['combustionAirFlowRate']?.toDouble(),
        vacuumAtTankVaporOutlet: data['vacuumAtTankVaporOutlet']?.toDouble(),
        exhaustTemperature: data['exhaustTemperature']?.toDouble(),
        totalizer: data['totalizer']?.toDouble(),
        observations: data['observations'] ?? '',
        operatorId: data['operatorId'] ?? '',
        validated: data['validated'] ?? false,
      );
    }).toList();
  }

  Future<void> _saveToFirestore(
      String projectId, String logDate, ThermalReading reading) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('thermal_logs')
        .doc(logDate)
        .collection('readings')
        .doc('hour_${reading.hour}')
        .set({
      'hour': reading.hour,
      'timestamp': reading.timestamp,
      'inletReading': reading.inletReading,
      'outletReading': reading.outletReading,
      'toInletReadingH2S': reading.toInletReadingH2S,
      'lelInletReading': reading.lelInletReading,
      'vaporInletFlowRateFPM': reading.vaporInletFlowRateFPM,
      'vaporInletFlowRateBBL': reading.vaporInletFlowRateBBL,
      'tankRefillFlowRate': reading.tankRefillFlowRate,
      'combustionAirFlowRate': reading.combustionAirFlowRate,
      'vacuumAtTankVaporOutlet': reading.vacuumAtTankVaporOutlet,
      'exhaustTemperature': reading.exhaustTemperature,
      'totalizer': reading.totalizer,
      'observations': reading.observations,
      'operatorId': reading.operatorId,
      'validated': reading.validated,
    });
  }

  Future<Set<int>> _getFirestoreCompletedHours(
      String projectId, String logDate) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('thermal_logs')
        .doc(logDate)
        .collection('readings')
        .get();

    return snapshot.docs.map((doc) => doc.data()['hour'] as int).toSet();
  }

  // Private Hive methods
  Future<List<ThermalReading>> _getHiveThermalReadings(
      String projectId, String logDate) async {
    return await LocalDatabaseService.getThermalReadingsForDay(
        projectId, logDate);
  }

  Future<void> _saveToHive(
      String projectId, String logDate, ThermalReading reading) async {
    await LocalDatabaseService.saveThermalReading(projectId, logDate, reading);
  }

  Future<Set<int>> _getHiveCompletedHours(
      String projectId, String logDate) async {
    return await LocalDatabaseService.getCompletedHours(projectId, logDate);
  }

  // Sync management methods
  Future<void> _markAsSynced(String projectId, String logDate, int hour) async {
    // Remove from sync queue if it exists
    final pendingItems = await LocalDatabaseService.getPendingSyncOperations();
    final itemId = '${projectId}_${logDate}_$hour';

    for (final item in pendingItems) {
      if (item.id == itemId) {
        await LocalDatabaseService.updateSyncQueueEntry(itemId, remove: true);
        break;
      }
    }
  }

  Future<void> _markForSync(String projectId, String logDate, int hour) async {
    final syncEntry = SyncQueueEntry(
      id: '${projectId}_${logDate}_$hour',
      operation: 'create',
      collection: 'thermal_readings',
      documentId: 'hour_$hour',
      data: {
        'type': 'thermal_reading',
        'projectId': projectId,
        'logDate': logDate,
        'hour': hour,
      },
      createdAt: DateTime.now(),
    );

    await LocalDatabaseService.addToSyncQueue(syncEntry);
  }

  Future<void> _syncItemToFirestore(SyncQueueEntry item) async {
    if (item.data['type'] == 'thermal_reading') {
      final reading = await LocalDatabaseService.getThermalReading(
        item.data['projectId'],
        item.data['logDate'],
        item.data['hour'],
      );
      if (reading != null) {
        await _saveToFirestore(
          item.data['projectId'],
          item.data['logDate'],
          reading,
        );
      }
    }
  }
}

/// Provider for the hybrid data service
final hybridDataProvider = Provider<HybridDataProvider>((ref) {
  return HybridDataProvider(ref);
});

/// Provider for thermal readings using hybrid approach
final hybridThermalReadingsProvider =
    FutureProvider.family<List<ThermalReading>, Map<String, String>>(
        (ref, params) async {
  final hybridData = ref.watch(hybridDataProvider);
  return await hybridData.getThermalReadingsForDay(
    projectId: params['projectId']!,
    logDate: params['logDate']!,
  );
});

/// Provider for completed hours using hybrid approach
final hybridCompletedHoursProvider =
    FutureProvider.family<Set<int>, Map<String, String>>((ref, params) async {
  final hybridData = ref.watch(hybridDataProvider);
  return await hybridData.getCompletedHours(
    projectId: params['projectId']!,
    logDate: params['logDate']!,
  );
});

/// Provider that triggers background sync when connection becomes available
final backgroundSyncProvider = Provider<void>((ref) {
  final connectionState = ref.watch(connectionStateProvider);
  final hybridData = ref.watch(hybridDataProvider);

  // Trigger sync when coming online
  connectionState.when(
    data: (state) {
      if (state == ConnectionState.online) {
        Future.microtask(() async {
          print('🔄 Connection restored, starting background sync');
          await hybridData.syncPendingData();
        });
      }
    },
    loading: () {},
    error: (error, stack) {},
  );
});
