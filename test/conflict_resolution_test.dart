import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/models/conflict_resolution_models.dart';
import 'package:my_flutter_app/models/hive_models.dart';

void main() {
  group('Conflict Resolution Tests', () {
    group('ConflictType and Detection', () {
      test('DataConflict correctly identifies local-only changes', () {
        final conflict = DataConflict(
          recordId: 'test_1',
          type: ConflictType.localOnly,
          localData: {'key': 'local_value'},
          remoteData: {'key': 'remote_value'},
          localTimestamp: DateTime.now(),
          remoteTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
          detectedAt: DateTime.now(),
          recordType: 'LogEntry',
        );
        
        expect(conflict.canAutoResolve, true);
        expect(conflict.isLocalNewer, true);
        expect(conflict.description, 'Local changes only - safe to sync');
      });
      
      test('DataConflict correctly identifies timestamp violations', () {
        final now = DateTime.now();
        final conflict = DataConflict(
          recordId: 'test_violation',
          type: ConflictType.timestampViolation,
          localData: {'key': 'value'},
          remoteData: {'key': 'value'},
          localTimestamp: now.subtract(const Duration(hours: 2)),
          remoteTimestamp: now,
          detectedAt: now,
          recordType: 'LogEntry',
        );
        
        expect(conflict.canAutoResolve, false);
        expect(conflict.isLocalNewer, false);
        expect(conflict.isRemoteNewer, true);
        expect(conflict.description, 'Timestamp violation detected - potential backdating attempt');
      });
      
      test('DataConflict handles equal timestamps correctly', () {
        final timestamp = DateTime.now();
        final conflict = DataConflict(
          recordId: 'test_equal',
          type: ConflictType.bothModified,
          localData: {'key': 'local_value'},
          remoteData: {'key': 'remote_value'},
          localTimestamp: timestamp,
          remoteTimestamp: timestamp,
          detectedAt: DateTime.now(),
          recordType: 'LogEntry',
          conflictingFields: ['key'],
        );
        
        expect(conflict.hasEqualTimestamps, true);
        expect(conflict.isLocalNewer, false);
        expect(conflict.isRemoteNewer, false);
        expect(conflict.conflictingFields.contains('key'), true);
      });
      
      test('DataConflict serializes to JSON correctly', () {
        final now = DateTime.now();
        final conflict = DataConflict(
          recordId: 'json_test',
          type: ConflictType.bothModified,
          localData: {'temp': 25.5},
          remoteData: {'temp': 26.0},
          localTimestamp: now,
          remoteTimestamp: now.subtract(const Duration(minutes: 5)),
          detectedAt: now,
          recordType: 'LogEntry',
          conflictingFields: ['temp'],
        );
        
        final json = conflict.toJson();
        
        expect(json['recordId'], 'json_test');
        expect(json['type'], 'bothModified');
        expect(json['localData'], {'temp': 25.5});
        expect(json['remoteData'], {'temp': 26.0});
        expect(json['conflictingFields'], ['temp']);
        expect(json['canAutoResolve'], true);
      });
    });
    
    group('Conflict Resolution Strategies', () {
      test('ConflictResolutionResult tracks successful resolution', () {
        final result = ConflictResolutionResult(
          recordId: 'success_test',
          strategy: ConflictResolutionStrategy.lastWriteWins,
          wasResolved: true,
          resolvedData: {'key': 'resolved_value'},
          errorMessage: null,
          resolvedAt: DateTime.now(),
          originalConflictType: ConflictType.bothModified,
        );
        
        expect(result.isSuccess, true);
        expect(result.hasError, false);
        expect(result.resolvedData!['key'], 'resolved_value');
      });
      
      test('ConflictResolutionResult tracks failed resolution', () {
        final result = ConflictResolutionResult(
          recordId: 'failed_test',
          strategy: ConflictResolutionStrategy.manual,
          wasResolved: false,
          resolvedData: null,
          errorMessage: 'Manual resolution required',
          resolvedAt: DateTime.now(),
          originalConflictType: ConflictType.structuralMismatch,
        );
        
        expect(result.isSuccess, false);
        expect(result.hasError, true);
        expect(result.errorMessage, 'Manual resolution required');
      });
      
      test('ConflictResolutionConfig validates critical fields', () {
        const config = ConflictResolutionConfig(
          criticalFields: ['temperature', 'pressure'],
        );
        
        expect(config.isCriticalField('temperature'), true);
        expect(config.isCriticalField('pressure'), true);
        expect(config.isCriticalField('humidity'), false);
      });
      
      test('ConflictResolutionConfig validates timestamp differences', () {
        const config = ConflictResolutionConfig(
          maxTimestampDifference: Duration(minutes: 10),
        );
        
        final now = DateTime.now();
        final closeTime = now.add(const Duration(minutes: 5));
        final farTime = now.add(const Duration(minutes: 15));
        
        expect(config.isTimestampDifferenceAcceptable(now, closeTime), true);
        expect(config.isTimestampDifferenceAcceptable(now, farTime), false);
      });
    });
    
    group('Conflict Resolution Statistics', () {
      test('ConflictResolutionStats tracks conflicts correctly', () {
        final stats = ConflictResolutionStats();
        
        expect(stats.totalConflicts, 0);
        expect(stats.resolutionRate, 0.0);
        
        // Record a successful resolution
        final conflict1 = DataConflict(
          recordId: 'stats_test_1',
          type: ConflictType.bothModified,
          localData: {'key': 'value1'},
          remoteData: {'key': 'value2'},
          localTimestamp: DateTime.now(),
          remoteTimestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          detectedAt: DateTime.now(),
          recordType: 'LogEntry',
        );
        
        final result1 = ConflictResolutionResult(
          recordId: 'stats_test_1',
          strategy: ConflictResolutionStrategy.lastWriteWins,
          wasResolved: true,
          resolvedData: {'key': 'value1'},
          resolvedAt: DateTime.now(),
          originalConflictType: ConflictType.bothModified,
        );
        
        stats.recordConflict(conflict1, result1);
        
        expect(stats.totalConflicts, 1);
        expect(stats.resolvedConflicts, 1);
        expect(stats.resolutionRate, 100.0);
        expect(stats.conflictTypeCount[ConflictType.bothModified], 1);
        expect(stats.strategyUsageCount[ConflictResolutionStrategy.lastWriteWins], 1);
      });
      
      test('ConflictResolutionStats tracks timestamp violations', () {
        final stats = ConflictResolutionStats();
        
        final conflict = DataConflict(
          recordId: 'violation_test',
          type: ConflictType.timestampViolation,
          localData: {'key': 'value'},
          remoteData: {'key': 'value'},
          localTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
          remoteTimestamp: DateTime.now(),
          detectedAt: DateTime.now(),
          recordType: 'LogEntry',
        );
        
        final result = ConflictResolutionResult(
          recordId: 'violation_test',
          strategy: ConflictResolutionStrategy.manual,
          wasResolved: false,
          errorMessage: 'Timestamp violation',
          resolvedAt: DateTime.now(),
          originalConflictType: ConflictType.timestampViolation,
        );
        
        stats.recordConflict(conflict, result);
        
        expect(stats.timestampViolations, 1);
        expect(stats.timestampViolationRate, 100.0);
        expect(stats.manualResolutionRequired, 1);
      });
      
      test('ConflictResolutionStats calculates rates correctly', () {
        final stats = ConflictResolutionStats();
        
        // Add 3 conflicts: 2 resolved, 1 requiring manual resolution
        for (int i = 0; i < 3; i++) {
          final now = DateTime.now();
          final conflict = DataConflict(
            recordId: 'rate_test_$i',
            type: i < 2 ? ConflictType.bothModified : ConflictType.timestampViolation,
            localData: {'key': 'value$i'},
            remoteData: {'key': 'other_value$i'},
            localTimestamp: now,
            remoteTimestamp: now.subtract(Duration(minutes: i + 1)),
            detectedAt: now,
            recordType: 'LogEntry',
          );
          
          final result = ConflictResolutionResult(
            recordId: 'rate_test_$i',
            strategy: i < 2 ? ConflictResolutionStrategy.lastWriteWins : ConflictResolutionStrategy.manual,
            wasResolved: i < 2,
            resolvedData: i < 2 ? {'key': 'value$i'} : null,
            errorMessage: i < 2 ? null : 'Manual resolution required',
            resolvedAt: DateTime.now(),
            originalConflictType: i < 2 ? ConflictType.bothModified : ConflictType.timestampViolation,
          );
          
          stats.recordConflict(conflict, result);
        }
        
        expect(stats.totalConflicts, 3);
        expect(stats.resolvedConflicts, 2);
        expect(stats.manualResolutionRequired, 1);
        expect(stats.resolutionRate, closeTo(66.67, 0.01));
        expect(stats.timestampViolations, 1);
        expect(stats.timestampViolationRate, closeTo(33.33, 0.01));
      });
      
      test('ConflictResolutionStats maintains recent history', () {
        final stats = ConflictResolutionStats();
        
        final conflict = DataConflict(
          recordId: 'history_test',
          type: ConflictType.localOnly,
          localData: {'key': 'value'},
          remoteData: null,
          localTimestamp: DateTime.now(),
          remoteTimestamp: null,
          detectedAt: DateTime.now(),
          recordType: 'LogEntry',
        );
        
        stats.recordConflict(conflict, null);
        
        expect(stats.lastConflictTime, isNotNull);
        expect(stats.lastConflictTime!.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
      });
      
      test('ConflictResolutionStats serializes to JSON', () {
        final stats = ConflictResolutionStats();
        
        final conflict = DataConflict(
          recordId: 'json_stats_test',
          type: ConflictType.bothModified,
          localData: {'key': 'value'},
          remoteData: {'key': 'other_value'},
          localTimestamp: DateTime.now(),
          remoteTimestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          detectedAt: DateTime.now(),
          recordType: 'LogEntry',
        );
        
        final result = ConflictResolutionResult(
          recordId: 'json_stats_test',
          strategy: ConflictResolutionStrategy.lastWriteWins,
          wasResolved: true,
          resolvedData: {'key': 'value'},
          resolvedAt: DateTime.now(),
          originalConflictType: ConflictType.bothModified,
        );
        
        stats.recordConflict(conflict, result);
        
        final json = stats.toJson();
        
        expect(json['totalConflicts'], 1);
        expect(json['resolvedConflicts'], 1);
        expect(json['resolutionRate'], 100.0);
        expect(json['conflictTypeCount'], isA<Map>());
        expect(json['strategyUsageCount'], isA<Map>());
        expect(json.containsKey('lastConflictTime'), true);
      });
    });
    
    group('Integration Scenarios', () {
      test('Last-write-wins strategy with clear timestamps', () {
        final now = DateTime.now();
        final localNewer = DataConflict(
          recordId: 'lmw_test_1',
          type: ConflictType.bothModified,
          localData: {'temp': 25.5, 'updated': 'locally'},
          remoteData: {'temp': 24.0, 'updated': 'remotely'},
          localTimestamp: now,
          remoteTimestamp: now.subtract(const Duration(minutes: 5)),
          detectedAt: now,
          recordType: 'LogEntry',
          conflictingFields: ['temp', 'updated'],
        );
        
        expect(localNewer.isLocalNewer, true);
        expect(localNewer.canAutoResolve, true);
        
        // Simulate last-write-wins resolution (local wins)
        final expectedResolution = localNewer.localData;
        expect(expectedResolution!['temp'], 25.5);
        expect(expectedResolution['updated'], 'locally');
      });
      
      test('Remote-wins strategy for server authoritative data', () {
        final conflict = DataConflict(
          recordId: 'remote_wins_test',
          type: ConflictType.remoteOnly,
          localData: {'status': 'pending'},
          remoteData: {'status': 'approved'},
          localTimestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          remoteTimestamp: DateTime.now(),
          detectedAt: DateTime.now(),
          recordType: 'LogEntry',
        );
        
        expect(conflict.isRemoteNewer, true);
        expect(conflict.canAutoResolve, true);
        
        // Remote data should be used
        expect(conflict.remoteData!['status'], 'approved');
      });
      
      test('Manual resolution required for critical fields', () {
        const config = ConflictResolutionConfig(
          criticalFields: ['finalTemperature'],
        );
        
        final conflict = DataConflict(
          recordId: 'critical_test',
          type: ConflictType.bothModified,
          localData: {'finalTemperature': 100.0},
          remoteData: {'finalTemperature': 95.0},
          localTimestamp: DateTime.now(),
          remoteTimestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          detectedAt: DateTime.now(),
          recordType: 'LogEntry',
          conflictingFields: ['finalTemperature'],
        );
        
        // Critical field conflict should require manual resolution
        expect(config.isCriticalField('finalTemperature'), true);
        expect(conflict.conflictingFields.any((field) => config.isCriticalField(field)), true);
      });
      
      test('No-backdating rule enforcement', () {
        final now = DateTime.now();
        final backdateAttempt = DataConflict(
          recordId: 'backdate_test',
          type: ConflictType.timestampViolation,
          localData: {'temp': 25.0},
          remoteData: {'temp': 24.0},
          localTimestamp: now.subtract(const Duration(hours: 2)), // Trying to backdate
          remoteTimestamp: now,
          detectedAt: now,
          recordType: 'LogEntry',
        );
        
        expect(backdateAttempt.canAutoResolve, false);
        expect(backdateAttempt.type, ConflictType.timestampViolation);
        expect(backdateAttempt.description.contains('backdating'), true);
      });
    });
  });
}