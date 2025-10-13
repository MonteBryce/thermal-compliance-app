import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/thermal_reading.dart';
import '../services/offline_storage_service.dart';
import 'path_helper.dart';
import '../utils/timestamp_utils.dart';

class ThermalReadingService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Save thermal reading data for a specific hour
  Future<void> saveThermalReading({
    required String projectId,
    required String logId,
    required ThermalReading reading,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to save entries');
    }

    final docId = reading.hour.toString().padLeft(2, '0');
    final docRef = PathHelper.entryDocRef(_firestore, projectId, logId, docId);

    final docData = {
      'hour': reading.hour,
      'timestamp': reading.timestamp,
      'inletReading': reading.inletReading,
      'outletReading': reading.outletReading,
      'toInletReadingH2S': reading.toInletReadingH2S,
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
      'createdBy': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'synced': true,
    };

    try {
      final logDocRef = PathHelper.logDocRef(_firestore, projectId, logId);
      final existingLog = await logDocRef.get();
      final logUpdate = <String, dynamic>{
        'date': logId,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      final existingLogData = existingLog.data() as Map<String, dynamic>?;
      if (!existingLog.exists ||
          existingLogData == null ||
          !existingLogData.containsKey('createdAt')) {
        logUpdate['createdAt'] = FieldValue.serverTimestamp();
      }

      await logDocRef.set(logUpdate, SetOptions(merge: true));

      debugPrint('�o. Ensured log document exists for date: $logId');

      final existingEntry = await docRef.get();
      final existingEntryData = existingEntry.data() as Map<String, dynamic>?;
      if (!existingEntry.exists ||
          existingEntryData == null ||
          !existingEntryData.containsKey('createdAt')) {
        docData['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(docData, SetOptions(merge: true));

      debugPrint('�o. Thermal reading saved for hour ${reading.hour}');
      debugPrint(
          'dY"? Saved to: /projects/$projectId/logs/$logId/entries/$docId');
      debugPrint('dY"S Data: $docData');
    } catch (e) {
      debugPrint('�?O Error saving to Firestore: $e');

      // Save offline if Firestore fails
      await _saveOffline(projectId, logId, reading, docData);
      throw ThermalReadingSaveException(
        'Failed to save online. Entry saved offline for sync later.',
        isOfflineSaved: true,
      );
    }
  }

  /// Load all thermal readings for a specific log
  Future<List<ThermalReading>> loadThermalReadings({
    required String projectId,
    required String logId,
  }) async {
    try {
      final snapshot =
          await PathHelper.entriesCollectionRef(_firestore, projectId, logId)
              .orderBy('hour')
              .get();

      final readings = <ThermalReading>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data != null) {
            final reading =
                _mapDocumentToThermalReading(data as Map<String, dynamic>);
            readings.add(reading);
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing document ${doc.id}: $e');
          // Continue processing other documents
        }
      }

      debugPrint('✅ Loaded ${readings.length} thermal readings');
      return readings;
    } catch (e) {
      debugPrint('❌ Error loading thermal readings: $e');

      // Try to load offline data as fallback
      return await _loadOfflineReadings(projectId, logId);
    }
  }

  /// Load thermal reading for a specific hour
  Future<ThermalReading?> loadThermalReadingForHour({
    required String projectId,
    required String logId,
    required int hour,
  }) async {
    final docId = hour.toString().padLeft(2, '0');

    try {
      final doc =
          await PathHelper.entryDocRef(_firestore, projectId, logId, docId)
              .get();

      if (!doc.exists) {
        debugPrint(
            '❌ No document found for hour $hour at /projects/$projectId/logs/$logId/entries/$docId');
        return null;
      }

      final data = doc.data()!;
      debugPrint('✅ Loaded thermal reading for hour $hour');
      debugPrint('📊 Raw data: $data');

      final thermalReading =
          _mapDocumentToThermalReading(data as Map<String, dynamic>);
      debugPrint('🔄 Mapped to: ${thermalReading.toJson()}');

      return thermalReading;
    } catch (e) {
      debugPrint('❌ Error loading thermal reading for hour $hour: $e');

      // Try offline fallback
      return await _loadOfflineReadingForHour(projectId, logId, hour);
    }
  }

  /// Check which hours have data
  Future<Set<int>> getCompletedHours({
    required String projectId,
    required String logId,
  }) async {
    try {
      final snapshot =
          await PathHelper.entriesCollectionRef(_firestore, projectId, logId)
              .get();

      final completedHours = <int>{};

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final hour = (data as Map<String, dynamic>?)?['hour'] as int?;
          if (hour != null) {
            completedHours.add(hour);
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing hour from document ${doc.id}: $e');
        }
      }

      return completedHours;
    } catch (e) {
      debugPrint('❌ Error getting completed hours: $e');
      return <int>{};
    }
  }

  /// Sync pending offline entries
  Future<void> syncOfflineEntries() async {
    final pendingEntries = await OfflineStorageService.getPendingEntries();

    for (final entry in pendingEntries) {
      try {
        final projectId = entry['projectId'] as String;
        final logId = entry['logId'] as String;
        final data = entry['data'] as Map<String, dynamic>;

        // Reconstruct ThermalReading from offline data
        final reading = _mapDocumentToThermalReading(data);

        // Try to save online
        await saveThermalReading(
          projectId: projectId,
          logId: logId,
          reading: reading,
        );

        // If successful, remove from offline storage
        await OfflineStorageService.deletePendingEntry(
          projectId: projectId,
          logId: logId,
          hour: entry['hour'] as String,
        );

        debugPrint('✅ Synced offline entry for hour ${reading.hour}');
      } catch (e) {
        debugPrint('❌ Failed to sync offline entry: $e');
        // Continue with other entries
      }
    }
  }

  /// Check if there are unsynced offline entries
  Future<bool> hasUnsyncedEntries() async {
    return await OfflineStorageService.hasPendingEntries();
  }

  // Private helper methods

  Future<void> _saveOffline(
    String projectId,
    String logId,
    ThermalReading reading,
    Map<String, dynamic> docData,
  ) async {
    final offlineData = Map<String, dynamic>.from(docData);
    offlineData['createdAt'] = reading.timestamp;
    offlineData['updatedAt'] = reading.timestamp;
    offlineData['synced'] = false;

    await OfflineStorageService.savePendingEntry(
      projectId: projectId,
      logId: logId,
      hour: reading.hour.toString().padLeft(2, '0'),
      data: offlineData,
    );
  }

  Future<List<ThermalReading>> _loadOfflineReadings(
    String projectId,
    String logId,
  ) async {
    try {
      final pendingEntries = await OfflineStorageService.getPendingEntries();
      final readings = <ThermalReading>[];

      for (final entry in pendingEntries) {
        if (entry['projectId'] == projectId && entry['logId'] == logId) {
          try {
            final data = entry['data'] as Map<String, dynamic>;
            final reading = _mapDocumentToThermalReading(data);
            readings.add(reading);
          } catch (e) {
            debugPrint('⚠️ Error parsing offline entry: $e');
          }
        }
      }

      return readings;
    } catch (e) {
      debugPrint('❌ Error loading offline readings: $e');
      return [];
    }
  }

  Future<ThermalReading?> _loadOfflineReadingForHour(
    String projectId,
    String logId,
    int hour,
  ) async {
    try {
      final pendingEntries = await OfflineStorageService.getPendingEntries();

      for (final entry in pendingEntries) {
        if (entry['projectId'] == projectId &&
            entry['logId'] == logId &&
            entry['hour'] == hour.toString().padLeft(2, '0')) {
          try {
            final data = entry['data'] as Map<String, dynamic>;
            return _mapDocumentToThermalReading(data);
          } catch (e) {
            debugPrint('⚠️ Error parsing offline entry for hour $hour: $e');
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error loading offline reading for hour $hour: $e');
      return null;
    }
  }

  ThermalReading _mapDocumentToThermalReading(Map<String, dynamic> data) {
    return ThermalReading(
      hour: data['hour'] ?? 0,
      timestamp:
          TimestampUtils.toDateTimeOrNow(data['timestamp']).toIso8601String(),
      inletReading: data['inletReading']?.toDouble(),
      outletReading: data['outletReading']?.toDouble(),
      toInletReadingH2S: data['toInletReadingH2S']?.toDouble(),
      vaporInletFlowRateFPM: data['vaporInletFlowRateFPM']?.toDouble(),
      vaporInletFlowRateBBL: data['vaporInletFlowRateBBL']?.toDouble(),
      tankRefillFlowRate: data['tankRefillFlowRate']?.toDouble(),
      combustionAirFlowRate: data['combustionAirFlowRate']?.toDouble(),
      vacuumAtTankVaporOutlet: data['vacuumAtTankVaporOutlet']?.toDouble(),
      exhaustTemperature: data['exhaustTemperature']?.toDouble(),
      totalizer: data['totalizer']?.toDouble(),
      observations: data['observations'] ?? '',
      operatorId: data['operatorId'] ?? 'OP001',
      validated: data['validated'] ?? false,
    );
  }
}

class ThermalReadingSaveException implements Exception {
  final String message;
  final bool isOfflineSaved;

  ThermalReadingSaveException(this.message, {this.isOfflineSaved = false});

  @override
  String toString() => message;
}
