import 'package:hive_flutter/hive_flutter.dart';
import '../models/thermal_log.dart';

/// Simple CRUD service for ThermalLog data using Hive for local storage
class ThermalLogService {
  static const String _boxName = 'thermalLogs';
  static Box<ThermalLog>? _box;

  /// Initialize the Hive box for ThermalLog
  static Future<void> initialize() async {
    if (_box != null && _box!.isOpen) return;
    
    try {
      _box = await Hive.openBox<ThermalLog>(_boxName);
    } catch (e) {
      throw Exception('Failed to initialize ThermalLogService: $e');
    }
  }

  /// Get the Hive box, ensuring it's initialized
  static Future<Box<ThermalLog>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      await initialize();
    }
    return _box!;
  }

  /// Save a thermal log (create or update)
  static Future<void> save(ThermalLog log) async {
    try {
      final box = await _getBox();
      await box.put(log.id, log);
    } catch (e) {
      throw Exception('Failed to save thermal log: $e');
    }
  }

  /// Get all thermal logs
  static Future<List<ThermalLog>> getAll() async {
    try {
      final box = await _getBox();
      return box.values.toList();
    } catch (e) {
      throw Exception('Failed to get all thermal logs: $e');
    }
  }

  /// Get a thermal log by ID
  static Future<ThermalLog?> getById(String id) async {
    try {
      final box = await _getBox();
      return box.get(id);
    } catch (e) {
      throw Exception('Failed to get thermal log by ID: $e');
    }
  }

  /// Update an existing thermal log
  static Future<void> update(ThermalLog log) async {
    try {
      final box = await _getBox();
      if (!box.containsKey(log.id)) {
        throw Exception('Thermal log with ID ${log.id} not found');
      }
      await box.put(log.id, log);
    } catch (e) {
      throw Exception('Failed to update thermal log: $e');
    }
  }

  /// Delete a thermal log by ID
  static Future<void> delete(String id) async {
    try {
      final box = await _getBox();
      if (!box.containsKey(id)) {
        throw Exception('Thermal log with ID $id not found');
      }
      await box.delete(id);
    } catch (e) {
      throw Exception('Failed to delete thermal log: $e');
    }
  }

  /// Clear all thermal logs (useful for testing)
  static Future<void> clear() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      throw Exception('Failed to clear thermal logs: $e');
    }
  }

  /// Get the count of thermal logs
  static Future<int> getCount() async {
    try {
      final box = await _getBox();
      return box.length;
    } catch (e) {
      throw Exception('Failed to get thermal log count: $e');
    }
  }

  /// Check if a thermal log exists by ID
  static Future<bool> exists(String id) async {
    try {
      final box = await _getBox();
      return box.containsKey(id);
    } catch (e) {
      throw Exception('Failed to check if thermal log exists: $e');
    }
  }

  /// Get thermal logs by project ID
  static Future<List<ThermalLog>> getByProjectId(String projectId) async {
    try {
      final box = await _getBox();
      return box.values.where((log) => log.projectId == projectId).toList();
    } catch (e) {
      throw Exception('Failed to get thermal logs by project ID: $e');
    }
  }

  /// Close the Hive box (useful for testing)
  static Future<void> close() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
      }
      _box = null;
    } catch (e) {
      throw Exception('Failed to close ThermalLogService: $e');
    }
  }
}