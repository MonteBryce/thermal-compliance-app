import 'package:cloud_firestore/cloud_firestore.dart';

/// Path helper service for consistent Firestore path construction
/// 
/// Canonical path structure:
/// projects/{projectId}/logs/{logId}/entries/{hour}
/// where logId = YYYYMMDD string; hour = two-digit "00".."23"
class PathHelper {
  /// Get a reference to a log document
  /// 
  /// [db] - FirebaseFirestore instance
  /// [projectId] - Project identifier
  /// [yyyymmdd] - Date in YYYYMMDD format (e.g., "20241201")
  /// 
  /// Returns: DocumentReference to projects/{projectId}/logs/{yyyymmdd}
  static DocumentReference logDocRef(
    FirebaseFirestore db,
    String projectId,
    String yyyymmdd,
  ) {
    return db
        .collection('projects')
        .doc(projectId)
        .collection('logs')
        .doc(yyyymmdd);
  }

  /// Get a reference to an entry document
  /// 
  /// [db] - FirebaseFirestore instance
  /// [projectId] - Project identifier
  /// [yyyymmdd] - Date in YYYYMMDD format (e.g., "20241201")
  /// [hour2] - Two-digit hour string (e.g., "00", "23")
  /// 
  /// Returns: DocumentReference to projects/{projectId}/logs/{yyyymmdd}/entries/{hour2}
  static DocumentReference entryDocRef(
    FirebaseFirestore db,
    String projectId,
    String yyyymmdd,
    String hour2,
  ) {
    if (!isValidHourId(hour2)) {
      throw ArgumentError('Invalid hour format. Expected "00" to "23", got: $hour2');
    }
    
    return logDocRef(db, projectId, yyyymmdd)
        .collection('entries')
        .doc(hour2);
  }

  /// Get a reference to the entries collection for a log
  /// 
  /// [db] - FirebaseFirestore instance
  /// [projectId] - Project identifier
  /// [yyyymmdd] - Date in YYYYMMDD format (e.g., "20241201")
  /// 
  /// Returns: CollectionReference to projects/{projectId}/logs/{yyyymmdd}/entries
  static CollectionReference entriesCollectionRef(
    FirebaseFirestore db,
    String projectId,
    String yyyymmdd,
  ) {
    return logDocRef(db, projectId, yyyymmdd)
        .collection('entries');
  }

  /// Get a reference to the logs collection for a project
  /// 
  /// [db] - FirebaseFirestore instance
  /// [projectId] - Project identifier
  /// 
  /// Returns: CollectionReference to projects/{projectId}/logs
  static CollectionReference logsCollectionRef(
    FirebaseFirestore db,
    String projectId,
  ) {
    return db
        .collection('projects')
        .doc(projectId)
        .collection('logs');
  }

  /// Get a reference to a project document
  /// 
  /// [db] - FirebaseFirestore instance
  /// [projectId] - Project identifier
  /// 
  /// Returns: DocumentReference to projects/{projectId}
  static DocumentReference projectDocRef(
    FirebaseFirestore db,
    String projectId,
  ) {
    return db
        .collection('projects')
        .doc(projectId);
  }

  /// Validate if a string is a valid hour identifier
  /// 
  /// [h] - Hour string to validate
  /// 
  /// Returns: true if the string is a valid two-digit hour (00-23), false otherwise
  static bool isValidHourId(String h) {
    if (h.length != 2) return false;
    
    try {
      final hour = int.parse(h);
      return hour >= 0 && hour <= 23;
    } catch (e) {
      return false;
    }
  }

  /// Convert DateTime to YYYYMMDD format string
  /// 
  /// [date] - DateTime to convert
  /// 
  /// Returns: String in YYYYMMDD format
  static String dateToYyyyMmDd(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// Convert hour integer to two-digit string
  /// 
  /// [hour] - Hour as integer (0-23)
  /// 
  /// Returns: Two-digit string (e.g., "00", "23")
  static String hourToHour2(int hour) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError('Hour must be between 0 and 23, got: $hour');
    }
    return hour.toString().padLeft(2, '0');
  }

  /// Convert two-digit hour string to integer
  /// 
  /// [hour2] - Two-digit hour string (e.g., "00", "23")
  /// 
  /// Returns: Hour as integer (0-23)
  static int hour2ToHour(String hour2) {
    if (!isValidHourId(hour2)) {
      throw ArgumentError('Invalid hour format. Expected "00" to "23", got: $hour2');
    }
    return int.parse(hour2);
  }

  /// Get all valid hour identifiers
  /// 
  /// Returns: List of all valid hour strings from "00" to "23"
  static List<String> getAllHourIds() {
    return List.generate(24, (i) => hourToHour2(i));
  }

  /// Check if a string is a valid YYYYMMDD format
  /// 
  /// [yyyymmdd] - String to validate
  /// 
  /// Returns: true if valid YYYYMMDD format, false otherwise
  static bool isValidYyyyMmDd(String yyyymmdd) {
    if (yyyymmdd.length != 8) return false;
    
    try {
      final year = int.parse(yyyymmdd.substring(0, 4));
      final month = int.parse(yyyymmdd.substring(4, 6));
      final day = int.parse(yyyymmdd.substring(6, 8));
      
      if (year < 1900 || year > 2100) return false;
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;
      
      // Basic validation - could be enhanced with actual calendar validation
      return true;
    } catch (e) {
      return false;
    }
  }
}
