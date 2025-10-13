import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility helpers for normalizing Firestore timestamp values that may
/// arrive as [Timestamp], ISO8601 [String], or [DateTime].
class TimestampUtils {
  const TimestampUtils._();

  /// Convert a Firestore value into a [DateTime]. Returns `null` when the
  /// value is missing or cannot be parsed.
  static DateTime? toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Convert Firestore value to a [DateTime], falling back to [fallback]
  /// (or `DateTime.now()` when fallback is omitted).
  static DateTime toDateTimeOrNow(dynamic value, {DateTime? fallback}) {
    return toDateTime(value) ?? fallback ?? DateTime.now();
  }
}
