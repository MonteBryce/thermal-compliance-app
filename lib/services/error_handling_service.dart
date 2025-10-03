import 'package:flutter/foundation.dart';

/// Centralized error handling service for consistent error management
class ErrorHandlingService {
  /// Log error with context and stack trace
  static void logError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  ]) {
    final timestamp = DateTime.now().toIso8601String();
    final errorType = error.runtimeType.toString();

    debugPrint('🔴 ERROR [$timestamp] in $context:');
    debugPrint('   Type: $errorType');
    debugPrint('   Message: $error');

    if (additionalData?.isNotEmpty == true) {
      debugPrint('   Data: $additionalData');
    }

    if (stackTrace != null) {
      debugPrint('   Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
    }

    // TODO: In production, send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
  }

  /// Log warning with context
  static void logWarning(
    String context,
    String message, [
    Map<String, dynamic>? additionalData,
  ]) {
    final timestamp = DateTime.now().toIso8601String();

    debugPrint('🟡 WARNING [$timestamp] in $context:');
    debugPrint('   Message: $message');

    if (additionalData?.isNotEmpty == true) {
      debugPrint('   Data: $additionalData');
    }
  }

  /// Create user-friendly error message from exception
  static String getUserFriendlyMessage(dynamic error) {
    if (error is ServiceException) {
      return error.userMessage;
    }

    if (error.toString().contains('SecurityException')) {
      return 'Security validation failed. Please check your settings.';
    }

    // Network-related errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('Connection')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    }

    // Database/storage errors
    if (error.toString().contains('database') ||
        error.toString().contains('storage') ||
        error.toString().contains('Hive')) {
      return 'Data storage error. Please restart the app and try again.';
    }

    // Firebase errors
    if (error.toString().contains('firebase') ||
        error.toString().contains('FirebaseException')) {
      return 'Cloud service temporarily unavailable. Your data is saved locally.';
    }

    // OCR/API errors
    if (error.toString().contains('OCR') ||
        error.toString().contains('API')) {
      return 'Service temporarily unavailable. Please try again later.';
    }

    // Generic fallback
    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle error with context and return result
  static void handleError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    logError(context, error, stackTrace);

    throw ServiceException(
      'Operation failed in $context',
      'OPERATION_FAILED',
      error,
      getUserFriendlyMessage(error),
    );
  }

  /// Wrap async operation with error handling
  static Future<T> wrapAsync<T>(
    String context,
    Future<T> Function() operation, [
    T? fallbackValue,
  ]) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      if (fallbackValue != null) {
        logError(context, error, stackTrace);
        return fallbackValue;
      }
      handleError(context, error, stackTrace);
      rethrow;
    }
  }

  /// Wrap sync operation with error handling
  static T wrapSync<T>(
    String context,
    T Function() operation, [
    T? fallbackValue,
  ]) {
    try {
      return operation();
    } catch (error, stackTrace) {
      if (fallbackValue != null) {
        logError(context, error, stackTrace);
        return fallbackValue;
      }
      handleError(context, error, stackTrace);
      rethrow;
    }
  }

  /// Check if error is recoverable
  static bool isRecoverableError(dynamic error) {
    // Network errors are typically recoverable
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('Connection')) {
      return true;
    }

    // Firebase errors may be recoverable
    if (error.toString().contains('firebase') ||
        error.toString().contains('FirebaseException')) {
      return true;
    }

    // API/service errors may be recoverable
    if (error.toString().contains('HTTP') ||
        error.toString().contains('API')) {
      return true;
    }

    // Security and validation errors are typically not recoverable
    if (error.toString().contains('SecurityException') ||
        error is ValidationException) {
      return false;
    }

    // Default to recoverable for user experience
    return true;
  }

  /// Get retry suggestion based on error type
  static String getRetryMessage(dynamic error) {
    if (!isRecoverableError(error)) {
      return 'Please check your input and try again.';
    }

    if (error.toString().contains('network') ||
        error.toString().contains('Connection')) {
      return 'Check your internet connection and try again.';
    }

    if (error.toString().contains('firebase') ||
        error.toString().contains('API')) {
      return 'The service is temporarily unavailable. Try again in a moment.';
    }

    return 'Please try again.';
  }
}

/// Base service exception with user-friendly messaging
class ServiceException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;
  final String userMessage;

  const ServiceException(
    this.message,
    this.code,
    this.originalError,
    this.userMessage,
  );

  @override
  String toString() => 'ServiceException($code): $message';
}

/// Validation exception for input/data validation errors
class ValidationException extends ServiceException {
  const ValidationException(String message, [dynamic originalError])
      : super(
          message,
          'VALIDATION_ERROR',
          originalError,
          message, // Validation messages are usually user-friendly
        );
}

/// Network exception for connectivity issues
class NetworkException extends ServiceException {
  const NetworkException(String message, [dynamic originalError])
      : super(
          message,
          'NETWORK_ERROR',
          originalError,
          'Network connection issue. Please check your internet connection.',
        );
}

/// Database exception for storage issues
class DatabaseException extends ServiceException {
  const DatabaseException(String message, [dynamic originalError])
      : super(
          message,
          'DATABASE_ERROR',
          originalError,
          'Data storage error. Please restart the app and try again.',
        );
}