import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/job_data.dart';

/// Service to preserve navigation state across app restarts
class NavigationStateService {
  static const String _currentProjectKey = 'current_project';
  static const String _currentLogIdKey = 'current_log_id';
  static const String _lastRouteKey = 'last_route';
  
  /// Save current project to persistent storage
  static Future<void> saveCurrentProject(JobData job) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jobJson = jsonEncode(job.toJson());
      await prefs.setString(_currentProjectKey, jobJson);
    } catch (e) {
      print('Error saving current project: $e');
    }
  }
  
  /// Get current project from persistent storage
  static Future<JobData?> getCurrentProject() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jobJson = prefs.getString(_currentProjectKey);
      if (jobJson != null) {
        final jobMap = jsonDecode(jobJson) as Map<String, dynamic>;
        return JobData.fromJson(jobMap);
      }
    } catch (e) {
      print('Error loading current project: $e');
    }
    return null;
  }
  
  /// Save current log ID
  static Future<void> saveCurrentLogId(String logId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentLogIdKey, logId);
    } catch (e) {
      print('Error saving current log ID: $e');
    }
  }
  
  /// Get current log ID
  static Future<String?> getCurrentLogId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentLogIdKey);
    } catch (e) {
      print('Error loading current log ID: $e');
    }
    return null;
  }
  
  /// Save last route for navigation restoration
  static Future<void> saveLastRoute(String route, Map<String, String>? pathParams) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routeData = {
        'route': route,
        'pathParams': pathParams ?? {},
      };
      await prefs.setString(_lastRouteKey, jsonEncode(routeData));
    } catch (e) {
      print('Error saving last route: $e');
    }
  }
  
  /// Get last route for navigation restoration
  static Future<Map<String, dynamic>?> getLastRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routeJson = prefs.getString(_lastRouteKey);
      if (routeJson != null) {
        return jsonDecode(routeJson) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error loading last route: $e');
    }
    return null;
  }
  
  /// Clear all saved navigation state
  static Future<void> clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentProjectKey);
      await prefs.remove(_currentLogIdKey);
      await prefs.remove(_lastRouteKey);
    } catch (e) {
      print('Error clearing navigation state: $e');
    }
  }
}