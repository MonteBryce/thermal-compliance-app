import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive_models.dart';
import '../models/thermal_log.dart';

class OfflineStorageService {
  static const String _pendingEntriesBox = 'pendingEntries';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();
    
    // Register all type adapters with checks to prevent duplicate registration
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LogEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DailyMetricAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CachedProjectAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SyncQueueEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ThermalLogAdapter());
    }
    
    // Open boxes for different data types
    await Hive.openBox<Map>(_pendingEntriesBox);
    await Hive.openBox<LogEntry>('logEntries');
    await Hive.openBox<DailyMetric>('dailyMetrics');
    await Hive.openBox<UserSession>('userSessions');
    await Hive.openBox<CachedProject>('cachedProjects');
    await Hive.openBox<SyncQueueEntry>('syncQueue');
    await Hive.openBox<ThermalLog>('thermalLogs');
    
    _initialized = true;
  }

  static Future<void> savePendingEntry({
    required String projectId,
    required String logId,
    required String hour,
    required Map<String, dynamic> data,
  }) async {
    final box = Hive.box<Map>(_pendingEntriesBox);
    final key = '${projectId}_${logId}_$hour';
    await box.put(key, {
      'projectId': projectId,
      'logId': logId,
      'hour': hour,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingEntries() async {
    final box = Hive.box<Map>(_pendingEntriesBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> deletePendingEntry({
    required String projectId,
    required String logId,
    required String hour,
  }) async {
    final box = Hive.box<Map>(_pendingEntriesBox);
    final key = '${projectId}_${logId}_$hour';
    await box.delete(key);
  }

  static Future<void> clearAllPendingEntries() async {
    final box = Hive.box<Map>(_pendingEntriesBox);
    await box.clear();
  }

  static Future<bool> hasPendingEntries() async {
    final box = Hive.box<Map>(_pendingEntriesBox);
    return box.isNotEmpty;
  }
}