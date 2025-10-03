import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service for implementing exponential backoff retry logic with jitter
class RetryService {
  static const int _defaultMaxRetries = 3;
  static const Duration _defaultBaseDelay = Duration(seconds: 1);
  static const Duration _defaultMaxDelay = Duration(minutes: 5);
  static const double _defaultJitterFactor = 0.1;

  /// Execute operation with exponential backoff retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = _defaultMaxRetries,
    Duration baseDelay = _defaultBaseDelay,
    Duration maxDelay = _defaultMaxDelay,
    double jitterFactor = _defaultJitterFactor,
    bool Function(Exception)? shouldRetry,
    void Function(int attempt, Exception error)? onRetry,
  }) async {
    var attempt = 0;
    Exception? lastException;

    while (attempt <= maxRetries) {
      try {
        debugPrint('RetryService: Attempt ${attempt + 1}/${maxRetries + 1}');
        final result = await operation();
        
        if (attempt > 0) {
          debugPrint('RetryService: Operation succeeded after $attempt retries');
        }
        
        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Check if we should retry this specific error
        if (shouldRetry != null && !shouldRetry(lastException)) {
          debugPrint('RetryService: Error not retryable: ${lastException.toString()}');
          throw lastException;
        }
        
        // If this was the last attempt, throw the error
        if (attempt >= maxRetries) {
          debugPrint('RetryService: Max retries exceeded, failing with: ${lastException.toString()}');
          throw lastException;
        }
        
        attempt++;
        
        // Calculate delay with exponential backoff and jitter
        final delay = _calculateDelay(
          attempt: attempt,
          baseDelay: baseDelay,
          maxDelay: maxDelay,
          jitterFactor: jitterFactor,
        );
        
        debugPrint('RetryService: Attempt $attempt failed: ${lastException.toString()}');
        debugPrint('RetryService: Retrying in ${delay.inMilliseconds}ms');
        
        if (onRetry != null) {
          onRetry(attempt, lastException);
        }
        
        await Future.delayed(delay);
      }
    }
    
    // This should never be reached, but just in case
    throw lastException ?? Exception('Unknown error in retry operation');
  }

  /// Calculate delay with exponential backoff and jitter
  static Duration _calculateDelay({
    required int attempt,
    required Duration baseDelay,
    required Duration maxDelay,
    required double jitterFactor,
  }) {
    // Exponential backoff: baseDelay * 2^(attempt-1)
    final exponentialDelay = baseDelay.inMilliseconds * pow(2, attempt - 1);
    
    // Cap at max delay
    final cappedDelay = min(exponentialDelay.toDouble(), maxDelay.inMilliseconds.toDouble());
    
    // Add jitter to prevent thundering herd problem
    final jitterAmount = cappedDelay * jitterFactor;
    final jitter = (Random().nextDouble() - 0.5) * 2 * jitterAmount;
    
    final finalDelay = cappedDelay + jitter;
    
    return Duration(milliseconds: max(0, finalDelay.round()));
  }

  /// Check if an error is retryable based on common patterns
  static bool isRetryableError(Exception error) {
    final errorMessage = error.toString().toLowerCase();
    
    // Network and connectivity errors
    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('socket')) {
      return true;
    }
    
    // Firestore specific errors
    if (errorMessage.contains('unavailable') ||
        errorMessage.contains('deadline exceeded') ||
        errorMessage.contains('resource exhausted') ||
        errorMessage.contains('internal error') ||
        errorMessage.contains('cancelled')) {
      return true;
    }
    
    // Rate limiting
    if (errorMessage.contains('rate limit') ||
        errorMessage.contains('quota exceeded') ||
        errorMessage.contains('too many requests')) {
      return true;
    }
    
    // Temporary server issues
    if (errorMessage.contains('service unavailable') ||
        errorMessage.contains('bad gateway') ||
        errorMessage.contains('gateway timeout')) {
      return true;
    }
    
    return false;
  }

  /// Check if an error indicates permanent failure (don't retry)
  static bool isPermanentError(Exception error) {
    final errorMessage = error.toString().toLowerCase();
    
    // Authentication and authorization errors
    if (errorMessage.contains('unauthorized') ||
        errorMessage.contains('forbidden') ||
        errorMessage.contains('permission denied') ||
        errorMessage.contains('authentication')) {
      return true;
    }
    
    // Client errors
    if (errorMessage.contains('bad request') ||
        errorMessage.contains('not found') ||
        errorMessage.contains('invalid argument') ||
        errorMessage.contains('already exists')) {
      return true;
    }
    
    // Data validation errors
    if (errorMessage.contains('validation') ||
        errorMessage.contains('invalid data') ||
        errorMessage.contains('malformed')) {
      return true;
    }
    
    return false;
  }
}

/// Configuration class for retry operations
class RetryConfig {
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final double jitterFactor;
  final bool Function(Exception)? shouldRetry;

  const RetryConfig({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 5),
    this.jitterFactor = 0.1,
    this.shouldRetry,
  });

  /// Conservative retry config for critical operations
  static const RetryConfig conservative = RetryConfig(
    maxRetries: 2,
    baseDelay: Duration(seconds: 2),
    maxDelay: Duration(minutes: 2),
  );

  /// Aggressive retry config for non-critical operations
  static const RetryConfig aggressive = RetryConfig(
    maxRetries: 5,
    baseDelay: Duration(milliseconds: 500),
    maxDelay: Duration(minutes: 10),
  );

  /// Network-specific retry config
  static const RetryConfig network = RetryConfig(
    maxRetries: 4,
    baseDelay: Duration(seconds: 1),
    maxDelay: Duration(minutes: 3),
    jitterFactor: 0.2,
  );

  Map<String, dynamic> toJson() {
    return {
      'maxRetries': maxRetries,
      'baseDelayMs': baseDelay.inMilliseconds,
      'maxDelayMs': maxDelay.inMilliseconds,
      'jitterFactor': jitterFactor,
    };
  }
}

/// Retry statistics for monitoring and debugging
class RetryStats {
  int totalRetries = 0;
  int successfulRetries = 0;
  int failedRetries = 0;
  int permanentFailures = 0;
  Duration totalRetryTime = Duration.zero;
  Map<String, int> errorCounts = {};
  DateTime? lastRetryTime;

  void recordRetry({
    required int attemptNumber,
    required Duration retryTime,
    required String errorType,
    required bool succeeded,
  }) {
    totalRetries++;
    totalRetryTime += retryTime;
    lastRetryTime = DateTime.now();
    
    errorCounts[errorType] = (errorCounts[errorType] ?? 0) + 1;
    
    if (succeeded) {
      successfulRetries++;
    } else {
      failedRetries++;
    }
  }

  void recordPermanentFailure(String errorType) {
    permanentFailures++;
    errorCounts[errorType] = (errorCounts[errorType] ?? 0) + 1;
  }

  double get successRate => totalRetries > 0 ? (successfulRetries / totalRetries) * 100 : 0;
  double get averageRetryTimeMs => totalRetries > 0 ? totalRetryTime.inMilliseconds / totalRetries : 0;

  Map<String, dynamic> toJson() {
    return {
      'totalRetries': totalRetries,
      'successfulRetries': successfulRetries,
      'failedRetries': failedRetries,
      'permanentFailures': permanentFailures,
      'successRate': successRate,
      'averageRetryTimeMs': averageRetryTimeMs,
      'totalRetryTimeMs': totalRetryTime.inMilliseconds,
      'errorCounts': errorCounts,
      'lastRetryTime': lastRetryTime?.toIso8601String(),
    };
  }
}