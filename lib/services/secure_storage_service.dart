import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'secure_prefs',
      preferencesKeyPrefix: 'secure_',
    ),
    iOptions: IOSOptions(),
    wOptions: WindowsOptions(),
  );

  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userEmailKey = 'user_email';
  static const String _sessionKey = 'session_data';
  static const String _ocrApiKeyKey = 'ocr_api_key';
  static const String _firebaseApiKeyKey = 'firebase_api_key';

  /// Store authentication token securely
  static Future<void> storeAuthToken(String token) async {
    try {
      await _storage.write(key: _authTokenKey, value: token);
      debugPrint('Auth token stored securely');
    } catch (e) {
      debugPrint('Failed to store auth token: $e');
      throw SecurityException('Failed to store authentication data securely');
    }
  }

  /// Retrieve authentication token
  static Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _authTokenKey);
    } catch (e) {
      debugPrint('Failed to retrieve auth token: $e');
      return null;
    }
  }

  /// Store user ID securely
  static Future<void> storeUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
      debugPrint('User ID stored securely');
    } catch (e) {
      debugPrint('Failed to store user ID: $e');
      throw SecurityException('Failed to store user data securely');
    }
  }

  /// Retrieve user ID
  static Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('Failed to retrieve user ID: $e');
      return null;
    }
  }

  /// Store refresh token securely
  static Future<void> storeRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
      debugPrint('Refresh token stored securely');
    } catch (e) {
      debugPrint('Failed to store refresh token: $e');
      throw SecurityException('Failed to store refresh token securely');
    }
  }

  /// Retrieve refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('Failed to retrieve refresh token: $e');
      return null;
    }
  }

  /// Store user email securely
  static Future<void> storeUserEmail(String email) async {
    try {
      await _storage.write(key: _userEmailKey, value: email);
      debugPrint('User email stored securely');
    } catch (e) {
      debugPrint('Failed to store user email: $e');
      throw SecurityException('Failed to store user email securely');
    }
  }

  /// Retrieve user email
  static Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _userEmailKey);
    } catch (e) {
      debugPrint('Failed to retrieve user email: $e');
      return null;
    }
  }

  /// Store session data securely (JSON string)
  static Future<void> storeSessionData(String sessionData) async {
    try {
      await _storage.write(key: _sessionKey, value: sessionData);
      debugPrint('Session data stored securely');
    } catch (e) {
      debugPrint('Failed to store session data: $e');
      throw SecurityException('Failed to store session data securely');
    }
  }

  /// Retrieve session data
  static Future<String?> getSessionData() async {
    try {
      return await _storage.read(key: _sessionKey);
    } catch (e) {
      debugPrint('Failed to retrieve session data: $e');
      return null;
    }
  }

  /// Clear all secure storage (used for logout)
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('All secure storage cleared');
    } catch (e) {
      debugPrint('Failed to clear secure storage: $e');
      throw SecurityException('Failed to clear secure storage');
    }
  }

  /// Clear specific key
  static Future<void> clearKey(String key) async {
    try {
      await _storage.delete(key: key);
      debugPrint('Secure storage key cleared: $key');
    } catch (e) {
      debugPrint('Failed to clear key $key: $e');
    }
  }

  /// Check if a key exists
  static Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      debugPrint('Failed to check key existence: $e');
      return false;
    }
  }

  /// Store generic secure data
  static Future<void> storeSecureData(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      debugPrint('Secure data stored for key: $key');
    } catch (e) {
      debugPrint('Failed to store secure data: $e');
      throw SecurityException('Failed to store data securely');
    }
  }

  /// Retrieve generic secure data
  static Future<String?> getSecureData(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('Failed to retrieve secure data: $e');
      return null;
    }
  }

  /// Store OCR API key securely
  static Future<void> storeOcrApiKey(String apiKey) async {
    try {
      await _storage.write(key: _ocrApiKeyKey, value: apiKey);
      debugPrint('OCR API key stored securely');
    } catch (e) {
      debugPrint('Failed to store OCR API key: $e');
      throw SecurityException('Failed to store OCR API key securely');
    }
  }

  /// Retrieve OCR API key
  static Future<String?> getOcrApiKey() async {
    try {
      return await _storage.read(key: _ocrApiKeyKey);
    } catch (e) {
      debugPrint('Failed to retrieve OCR API key: $e');
      return null;
    }
  }

  /// Store Firebase API key securely
  static Future<void> storeFirebaseApiKey(String apiKey) async {
    try {
      await _storage.write(key: _firebaseApiKeyKey, value: apiKey);
      debugPrint('Firebase API key stored securely');
    } catch (e) {
      debugPrint('Failed to store Firebase API key: $e');
      throw SecurityException('Failed to store Firebase API key securely');
    }
  }

  /// Retrieve Firebase API key
  static Future<String?> getFirebaseApiKey() async {
    try {
      return await _storage.read(key: _firebaseApiKeyKey);
    } catch (e) {
      debugPrint('Failed to retrieve Firebase API key: $e');
      return null;
    }
  }
}

/// Custom exception for security-related errors
class SecurityException implements Exception {
  final String message;

  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}