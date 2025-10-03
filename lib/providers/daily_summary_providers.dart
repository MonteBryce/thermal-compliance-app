import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/hive_models.dart';
import '../services/local_database_service.dart';
import '../services/auth_service.dart';
import '../models/thermal_reading.dart';
import 'hybrid_data_providers.dart';
import 'connection_providers.dart';

/// Provider for the selected date for viewing logs
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Provider for fetching all log entries for a specific date
final dailyLogEntriesProvider = FutureProvider.family<List<LogEntry>, DateTime>((ref, date) async {
  try {
    // Format date as YYYY-MM-DD string
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    // Fetch log entries from local database
    final entries = await LocalDatabaseService.getDateLogEntries(dateString);
    
    debugPrint('Fetched ${entries.length} log entries for date: $dateString');
    return entries;
  } catch (e) {
    debugPrint('Error fetching daily log entries: $e');
    throw Exception('Failed to load log entries for the selected date');
  }
});

/// Provider for the daily metric for a specific date
final dailyMetricProvider = FutureProvider.family<DailyMetric?, DateTime>((ref, date) async {
  try {
    // Get current user session to get project ID
    final session = await LocalDatabaseService.getCurrentUserSession();
    if (session?.currentProjectId == null) {
      debugPrint('No current project selected');
      return null;
    }

    // Format date as YYYY-MM-DD string
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    // Fetch daily metric from local database
    final metric = await LocalDatabaseService.getProjectDailyMetric(
      session!.currentProjectId!,
      dateString,
    );
    
    debugPrint('Fetched daily metric for date: $dateString, locked: ${metric?.isLocked}');
    return metric;
  } catch (e) {
    debugPrint('Error fetching daily metric: $e');
    return null;
  }
});

/// Combined provider for daily summary data
final dailySummaryProvider = Provider.family<AsyncValue<DailySummaryData>, DateTime>((ref, date) {
  final logEntries = ref.watch(dailyLogEntriesProvider(date));
  final dailyMetric = ref.watch(dailyMetricProvider(date));

  // If either is still loading, return loading state
  if (logEntries.isLoading || dailyMetric.isLoading) {
    return const AsyncValue.loading();
  }

  // If there's an error in log entries, return error
  if (logEntries.hasError) {
    return AsyncValue.error(logEntries.error!, logEntries.stackTrace!);
  }

  // Return combined data
  return AsyncValue.data(
    DailySummaryData(
      logEntries: logEntries.value ?? [],
      dailyMetric: dailyMetric.value,
    ),
  );
});

/// Stream provider for real-time updates to daily logs
final dailyLogEntriesStreamProvider = StreamProvider.family<List<LogEntry>, DateTime>((ref, date) async* {
  // Initial data
  final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  yield await LocalDatabaseService.getDateLogEntries(dateString);

  // Listen for changes (poll every 5 seconds for simplicity)
  // In production, you might want to use a more sophisticated approach
  await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
    final updatedEntries = await LocalDatabaseService.getDateLogEntries(dateString);
    yield updatedEntries;
  }
});

/// Provider for calculating daily summary statistics
final dailySummaryStatsProvider = Provider.family<DailySummaryStats, DateTime>((ref, date) {
  final summaryData = ref.watch(dailySummaryProvider(date));
  
  return summaryData.when(
    data: (data) {
      final entries = data.logEntries;
      final metric = data.dailyMetric;
      
      // Calculate statistics
      final totalEntries = entries.length;
      final completedEntries = entries.where((e) => e.status == 'completed').length;
      final pendingEntries = entries.where((e) => e.status == 'pending').length;
      final syncedEntries = entries.where((e) => e.isSynced).length;
      final unsyncedEntries = entries.where((e) => !e.isSynced).length;
      
      // Calculate hours worked (assuming entries have hour field)
      final uniqueHours = entries.map((e) => e.hour).toSet().length;
      
      return DailySummaryStats(
        totalEntries: totalEntries,
        completedEntries: completedEntries,
        pendingEntries: pendingEntries,
        syncedEntries: syncedEntries,
        unsyncedEntries: unsyncedEntries,
        hoursWorked: uniqueHours,
        isFinalized: metric?.isLocked ?? false,
        completionPercentage: metric?.completionPercentage ?? 0.0,
      );
    },
    loading: () => DailySummaryStats.empty(),
    error: (_, __) => DailySummaryStats.empty(),
  );
});

/// Notifier for managing log entry edits
class LogEntryEditNotifier extends StateNotifier<LogEntry?> {
  LogEntryEditNotifier() : super(null);

  void startEdit(LogEntry entry) {
    state = entry;
  }

  void updateField(String key, dynamic value) {
    if (state != null) {
      final updatedData = Map<String, dynamic>.from(state!.data);
      updatedData[key] = value;
      state = LogEntry(
        id: state!.id,
        projectId: state!.projectId,
        projectName: state!.projectName,
        date: state!.date,
        hour: state!.hour,
        data: updatedData,
        status: state!.status,
        createdAt: state!.createdAt,
        updatedAt: DateTime.now(),
        createdBy: state!.createdBy,
        isSynced: false, // Mark as unsynced after edit
        syncError: state!.syncError,
      );
    }
  }

  Future<bool> saveEdit() async {
    if (state == null) return false;
    
    try {
      state!.updatedAt = DateTime.now();
      state!.isSynced = false; // Mark as unsynced
      await LocalDatabaseService.saveLogEntry(state!);
      debugPrint('Log entry saved: ${state!.id}');
      return true;
    } catch (e) {
      debugPrint('Error saving log entry: $e');
      return false;
    }
  }

  void cancelEdit() {
    state = null;
  }
}

/// Provider for log entry edit notifier
final logEntryEditProvider = StateNotifierProvider<LogEntryEditNotifier, LogEntry?>((ref) {
  return LogEntryEditNotifier();
});

/// Provider for finalizing a day's logs
final finalizeDayProvider = Provider((ref) {
  return FinalizeDayService(ref);
});

class FinalizeDayService {
  final Ref ref;
  
  FinalizeDayService(this.ref);
  
  Future<bool> finalizeDay(DateTime date) async {
    try {
      // Get current project
      final session = await LocalDatabaseService.getCurrentUserSession();
      if (session?.currentProjectId == null) {
        throw Exception('No project selected');
      }
      
      // Format date
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Get or create daily metric
      var metric = await LocalDatabaseService.getProjectDailyMetric(
        session!.currentProjectId!,
        dateString,
      );
      
      if (metric == null) {
        // Create new metric
        final entries = await LocalDatabaseService.getDateLogEntries(dateString);
        final completedCount = entries.where((e) => e.status == 'completed').length;
        
        metric = DailyMetric(
          id: '${session.currentProjectId}_$dateString',
          projectId: session.currentProjectId!,
          date: dateString,
          totalEntries: entries.length,
          completedEntries: completedCount,
          completionStatus: 'finalized',
          summary: {
            'finalizedAt': DateTime.now().toIso8601String(),
            'finalizedBy': AuthService.getCurrentUserId() ?? 'unknown',
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: AuthService.getCurrentUserId() ?? 'unknown',
          isSynced: false,
          isLocked: true, // Lock the day
        );
      } else {
        // Update existing metric
        metric.isLocked = true;
        metric.completionStatus = 'finalized';
        metric.updatedAt = DateTime.now();
        metric.summary['finalizedAt'] = DateTime.now().toIso8601String();
        metric.summary['finalizedBy'] = AuthService.getCurrentUserId() ?? 'unknown';
      }
      
      // Save the metric
      await LocalDatabaseService.saveDailyMetric(metric);
      
      // Invalidate the providers to refresh UI
      ref.invalidate(dailyMetricProvider(date));
      ref.invalidate(dailyLogEntriesProvider(date));
      
      debugPrint('Day finalized successfully: $dateString');
      return true;
    } catch (e) {
      debugPrint('Error finalizing day: $e');
      return false;
    }
  }
  
  Future<bool> canFinalizeDay(DateTime date) async {
    try {
      // Check if day is already finalized
      final metric = await ref.read(dailyMetricProvider(date).future);
      if (metric?.isLocked == true) {
        return false; // Already finalized
      }
      
      // Check if there are any entries for the day
      final entries = await ref.read(dailyLogEntriesProvider(date).future);
      return entries.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking finalize status: $e');
      return false;
    }
  }
}

/// Data class for combined daily summary data
class DailySummaryData {
  final List<LogEntry> logEntries;
  final DailyMetric? dailyMetric;

  DailySummaryData({
    required this.logEntries,
    this.dailyMetric,
  });
}

/// Data class for daily summary statistics
class DailySummaryStats {
  final int totalEntries;
  final int completedEntries;
  final int pendingEntries;
  final int syncedEntries;
  final int unsyncedEntries;
  final int hoursWorked;
  final bool isFinalized;
  final double completionPercentage;

  DailySummaryStats({
    required this.totalEntries,
    required this.completedEntries,
    required this.pendingEntries,
    required this.syncedEntries,
    required this.unsyncedEntries,
    required this.hoursWorked,
    required this.isFinalized,
    required this.completionPercentage,
  });

  factory DailySummaryStats.empty() {
    return DailySummaryStats(
      totalEntries: 0,
      completedEntries: 0,
      pendingEntries: 0,
      syncedEntries: 0,
      unsyncedEntries: 0,
      hoursWorked: 0,
      isFinalized: false,
      completionPercentage: 0.0,
    );
  }
}

// ============ HYBRID THERMAL READING PROVIDERS ============

/// Provider for selected project ID for thermal readings
final selectedProjectProvider = StateProvider<String>((ref) {
  return 'DEMO-2025-001'; // Default project for demo
});

/// Hybrid provider for thermal readings using automatic Firestore/Hive switching
final hybridThermalReadingsForDayProvider = FutureProvider.family<List<ThermalReading>, Map<String, String>>((ref, params) async {
  final hybridData = ref.watch(hybridDataProvider);
  final connectionStatus = ref.watch(connectionStatusTextProvider);
  
  debugPrint('🔄 Loading thermal readings with connection: $connectionStatus');
  
  try {
    final readings = await hybridData.getThermalReadingsForDay(
      projectId: params['projectId']!,
      logDate: params['logDate']!,
    );
    
    debugPrint('✅ Loaded ${readings.length} thermal readings');
    return readings;
  } catch (e) {
    debugPrint('❌ Error loading thermal readings: $e');
    throw Exception('Failed to load thermal readings: $e');
  }
});

/// Hybrid provider for completed hours using automatic Firestore/Hive switching
final hybridCompletedHoursForDayProvider = FutureProvider.family<Set<int>, Map<String, String>>((ref, params) async {
  final hybridData = ref.watch(hybridDataProvider);
  
  try {
    final completedHours = await hybridData.getCompletedHours(
      projectId: params['projectId']!,
      logDate: params['logDate']!,
    );
    
    debugPrint('✅ Found ${completedHours.length} completed hours: $completedHours');
    return completedHours;
  } catch (e) {
    debugPrint('❌ Error loading completed hours: $e');
    return <int>{};
  }
});

/// Provider that combines project and date for easier use
final currentProjectDateProvider = Provider<Map<String, String>>((ref) {
  final selectedProject = ref.watch(selectedProjectProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
  
  return {
    'projectId': selectedProject,
    'logDate': formattedDate,
  };
});

/// Convenient provider for current day's thermal readings
final currentDayThermalReadingsProvider = FutureProvider<List<ThermalReading>>((ref) async {
  final params = ref.watch(currentProjectDateProvider);
  final readingsAsync = ref.watch(hybridThermalReadingsForDayProvider(params));
  return readingsAsync.when(
    data: (readings) => readings,
    loading: () => <ThermalReading>[],
    error: (error, stack) {
      debugPrint('Error in currentDayThermalReadingsProvider: $error');
      return <ThermalReading>[];
    },
  );
});

/// Convenient provider for current day's completed hours
final currentDayCompletedHoursProvider = FutureProvider<Set<int>>((ref) async {
  final params = ref.watch(currentProjectDateProvider);
  final hoursAsync = ref.watch(hybridCompletedHoursForDayProvider(params));
  return hoursAsync.when(
    data: (hours) => hours,
    loading: () => <int>{},
    error: (error, stack) {
      debugPrint('Error in currentDayCompletedHoursProvider: $error');
      return <int>{};
    },
  );
});

/// Provider for thermal reading statistics 
final thermalReadingStatsProvider = FutureProvider<ThermalReadingStats>((ref) async {
  final readings = await ref.watch(currentDayThermalReadingsProvider.future);
  final completedHours = await ref.watch(currentDayCompletedHoursProvider.future);
  
  final totalHours = 24;
  final loggedHours = readings.length;
  final validatedHours = completedHours.length;
  final pendingHours = loggedHours - validatedHours;
  
  final completionPercentage = loggedHours > 0 ? (validatedHours / totalHours) * 100 : 0.0;
  
  return ThermalReadingStats(
    totalHours: totalHours,
    loggedHours: loggedHours,
    validatedHours: validatedHours,
    pendingHours: pendingHours,
    missingHours: totalHours - loggedHours,
    completionPercentage: completionPercentage,
  );
});

/// Service class for saving thermal readings with hybrid support
class HybridThermalReadingService {
  final Ref ref;
  
  HybridThermalReadingService(this.ref);
  
  Future<bool> saveThermalReading({
    required String projectId,
    required String logDate,
    required ThermalReading reading,
  }) async {
    try {
      final hybridData = ref.read(hybridDataProvider);
      await hybridData.saveThermalReading(
        projectId: projectId,
        logDate: logDate,
        reading: reading,
      );
      
      // Invalidate providers to refresh UI
      final params = {'projectId': projectId, 'logDate': logDate};
      ref.invalidate(hybridThermalReadingsForDayProvider(params));
      ref.invalidate(hybridCompletedHoursForDayProvider(params));
      
      // Trigger background sync
      ref.read(backgroundSyncProvider);
      
      debugPrint('💾 Thermal reading saved successfully: ${reading.hour}h');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving thermal reading: $e');
      return false;
    }
  }
}

/// Provider for the hybrid thermal reading service
final hybridThermalReadingServiceProvider = Provider<HybridThermalReadingService>((ref) {
  return HybridThermalReadingService(ref);
});

/// Data class for thermal reading statistics
class ThermalReadingStats {
  final int totalHours;
  final int loggedHours;
  final int validatedHours;
  final int pendingHours;
  final int missingHours;
  final double completionPercentage;

  ThermalReadingStats({
    required this.totalHours,
    required this.loggedHours,
    required this.validatedHours,
    required this.pendingHours,
    required this.missingHours,
    required this.completionPercentage,
  });

  factory ThermalReadingStats.empty() {
    return ThermalReadingStats(
      totalHours: 24,
      loggedHours: 0,
      validatedHours: 0,
      pendingHours: 0,
      missingHours: 24,
      completionPercentage: 0.0,
    );
  }
}