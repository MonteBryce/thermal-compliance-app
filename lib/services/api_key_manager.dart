import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

/// Service for managing API keys securely across the application
class ApiKeyManager {
  /// Validate and store OCR API key
  static Future<bool> setOcrApiKey(String apiKey) async {
    try {
      if (apiKey.isEmpty) {
        throw ArgumentError('API key cannot be empty');
      }

      // Basic validation - should be alphanumeric with possible special chars
      if (!_isValidApiKeyFormat(apiKey)) {
        throw ArgumentError('Invalid API key format');
      }

      await SecureStorageService.storeOcrApiKey(apiKey);
      debugPrint('OCR API key configured successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to set OCR API key: $e');
      return false;
    }
  }

  /// Test OCR API key validity
  static Future<bool> testOcrApiKey() async {
    try {
      final String? apiKey = await SecureStorageService.getOcrApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return false;
      }

      // Add actual API test call here if needed
      // For now, just check if key exists and has proper format
      return _isValidApiKeyFormat(apiKey);
    } catch (e) {
      debugPrint('OCR API key test failed: $e');
      return false;
    }
  }

  /// Get OCR API key status
  static Future<ApiKeyStatus> getOcrApiKeyStatus() async {
    try {
      final String? apiKey = await SecureStorageService.getOcrApiKey();

      if (apiKey == null || apiKey.isEmpty) {
        return ApiKeyStatus.notConfigured;
      }

      if (!_isValidApiKeyFormat(apiKey)) {
        return ApiKeyStatus.invalid;
      }

      // Test the key (simplified validation)
      final bool isValid = await testOcrApiKey();
      return isValid ? ApiKeyStatus.valid : ApiKeyStatus.invalid;
    } catch (e) {
      debugPrint('Failed to get OCR API key status: $e');
      return ApiKeyStatus.error;
    }
  }

  /// Clear OCR API key
  static Future<void> clearOcrApiKey() async {
    try {
      await SecureStorageService.clearKey('ocr_api_key');
      debugPrint('OCR API key cleared');
    } catch (e) {
      debugPrint('Failed to clear OCR API key: $e');
    }
  }

  /// Validate and store Firebase API key
  static Future<bool> setFirebaseApiKey(String apiKey) async {
    try {
      if (apiKey.isEmpty) {
        throw ArgumentError('Firebase API key cannot be empty');
      }

      if (!_isValidApiKeyFormat(apiKey)) {
        throw ArgumentError('Invalid Firebase API key format');
      }

      await SecureStorageService.storeFirebaseApiKey(apiKey);
      debugPrint('Firebase API key configured successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to set Firebase API key: $e');
      return false;
    }
  }

  /// Get Firebase API key status
  static Future<ApiKeyStatus> getFirebaseApiKeyStatus() async {
    try {
      final String? apiKey = await SecureStorageService.getFirebaseApiKey();

      if (apiKey == null || apiKey.isEmpty) {
        return ApiKeyStatus.notConfigured;
      }

      if (!_isValidApiKeyFormat(apiKey)) {
        return ApiKeyStatus.invalid;
      }

      return ApiKeyStatus.valid;
    } catch (e) {
      debugPrint('Failed to get Firebase API key status: $e');
      return ApiKeyStatus.error;
    }
  }

  /// Clear Firebase API key
  static Future<void> clearFirebaseApiKey() async {
    try {
      await SecureStorageService.clearKey('firebase_api_key');
      debugPrint('Firebase API key cleared');
    } catch (e) {
      debugPrint('Failed to clear Firebase API key: $e');
    }
  }

  /// Get all API key statuses for settings screen
  static Future<Map<String, ApiKeyStatus>> getAllApiKeyStatuses() async {
    final results = await Future.wait([
      getOcrApiKeyStatus(),
      getFirebaseApiKeyStatus(),
    ]);

    return {
      'ocr': results[0],
      'firebase': results[1],
    };
  }

  /// Basic API key format validation
  static bool _isValidApiKeyFormat(String apiKey) {
    // Basic validation - at least 8 characters, alphanumeric with some special chars
    if (apiKey.length < 8) return false;

    // Check for common API key patterns
    final apiKeyPattern = RegExp(r'^[a-zA-Z0-9_\-\.]+$');
    return apiKeyPattern.hasMatch(apiKey);
  }

  /// Mask API key for display (show first 4 and last 4 characters)
  static String maskApiKey(String apiKey) {
    if (apiKey.length <= 8) {
      return '*' * apiKey.length;
    }

    final start = apiKey.substring(0, 4);
    final end = apiKey.substring(apiKey.length - 4);
    final middle = '*' * (apiKey.length - 8);

    return '$start$middle$end';
  }
}

/// API key status enumeration
enum ApiKeyStatus {
  notConfigured,
  valid,
  invalid,
  error,
}

/// Extension for API key status display
extension ApiKeyStatusExtension on ApiKeyStatus {
  String get displayText {
    switch (this) {
      case ApiKeyStatus.notConfigured:
        return 'Not Configured';
      case ApiKeyStatus.valid:
        return 'Valid';
      case ApiKeyStatus.invalid:
        return 'Invalid';
      case ApiKeyStatus.error:
        return 'Error';
    }
  }

  bool get isHealthy => this == ApiKeyStatus.valid;
}