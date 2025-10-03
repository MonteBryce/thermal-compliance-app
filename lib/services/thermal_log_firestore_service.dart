import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/thermal_log.dart';
import 'auth_service.dart';

/// Firestore CRUD service for ThermalLog data
class ThermalLogFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'thermal_logs';

  /// Get collection reference (user-scoped)
  static CollectionReference<Map<String, dynamic>> _getCollection() {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_collection);
  }

  /// Create a new thermal log in Firestore
  static Future<void> create(ThermalLog log) async {
    try {
      final collection = _getCollection();
      await collection.doc(log.id).set(log.toFirestore());
      print('ThermalLog created in Firestore: ${log.id}');
    } catch (e) {
      throw Exception('Failed to create thermal log in Firestore: $e');
    }
  }

  /// Read all thermal logs from Firestore
  static Future<List<ThermalLog>> getAll() async {
    try {
      final collection = _getCollection();
      final snapshot = await collection
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ThermalLog.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get thermal logs from Firestore: $e');
    }
  }

  /// Read thermal logs by project ID
  static Future<List<ThermalLog>> getByProjectId(String projectId) async {
    try {
      final collection = _getCollection();
      final snapshot = await collection
          .where('projectId', isEqualTo: projectId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ThermalLog.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get thermal logs by project from Firestore: $e');
    }
  }

  /// Read a single thermal log by ID
  static Future<ThermalLog?> getById(String id) async {
    try {
      final collection = _getCollection();
      final doc = await collection.doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return ThermalLog.fromFirestore(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get thermal log from Firestore: $e');
    }
  }

  /// Update an existing thermal log
  static Future<void> update(ThermalLog log) async {
    try {
      final collection = _getCollection();
      final updatedLog = log.copyWith(
        updatedAt: DateTime.now(),
      );
      await collection.doc(log.id).update(updatedLog.toFirestore());
      print('ThermalLog updated in Firestore: ${log.id}');
    } catch (e) {
      throw Exception('Failed to update thermal log in Firestore: $e');
    }
  }

  /// Delete a thermal log by ID
  static Future<void> delete(String id) async {
    try {
      final collection = _getCollection();
      await collection.doc(id).delete();
      print('ThermalLog deleted from Firestore: $id');
    } catch (e) {
      throw Exception('Failed to delete thermal log from Firestore: $e');
    }
  }

  /// Batch write multiple thermal logs (for sync operations)
  static Future<void> batchWrite(List<ThermalLog> logs) async {
    try {
      final batch = _firestore.batch();
      final collection = _getCollection();

      for (final log in logs) {
        batch.set(
          collection.doc(log.id),
          log.toFirestore(),
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      print('Batch wrote ${logs.length} thermal logs to Firestore');
    } catch (e) {
      throw Exception('Failed to batch write thermal logs to Firestore: $e');
    }
  }

  /// Listen to real-time updates for a project
  static Stream<List<ThermalLog>> streamByProjectId(String projectId) {
    try {
      final collection = _getCollection();
      return collection
          .where('projectId', isEqualTo: projectId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ThermalLog.fromFirestore(doc.data()))
              .toList());
    } catch (e) {
      throw Exception('Failed to stream thermal logs from Firestore: $e');
    }
  }
}