import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/offline_storage_service.dart';
import '../services/validation_service.dart';
import 'path_helper.dart';

class LogEntryService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<List<QueryDocumentSnapshot>> getEntriesForLog({
    required String projectId,
    required String logId,
  }) async {
    try {
      final querySnapshot = await PathHelper.entriesCollectionRef(_firestore, projectId, logId)
          .orderBy('hour')
          .get();

      return querySnapshot.docs;
    } catch (e) {
      debugPrint('Error fetching log entries: $e');
      rethrow;
    }
  }

  Future<void> saveEntry({
    required String projectId,
    required String logId,
    required String logType,
    required int hour,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to save entries');
    }

    // Validate data
    final errors = ValidationService.validateEntry(
      logType: logType,
      data: data,
    );

    if (errors.isNotEmpty) {
      throw ValidationException(errors);
    }

    // Add metadata
    final enrichedData = {
      ...data,
      'createdBy': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'logType': logType,
      'hour': hour,
      'synced': true,
    };

    try {
      // Try to save to Firebase
      final docRef = PathHelper.entryDocRef(_firestore, projectId, logId, hour.toString().padLeft(2, '0'));

      await docRef.set(enrichedData, SetOptions(merge: merge));
    } catch (e) {
      debugPrint('Error saving to Firebase: $e');

      // On any Firebase error, save locally
      final offlineData = {
        ...data,
        'createdBy': user.uid,
        'timestamp': DateTime.now().toIso8601String(),
        'logType': logType,
        'hour': hour,
        'synced': false,
      };

      await OfflineStorageService.savePendingEntry(
        projectId: projectId,
        logId: logId,
        hour: hour.toString().padLeft(2, '0'),
        data: offlineData,
      );

      throw SaveException(
        'Failed to save online. Entry saved offline.',
        isOfflineSaved: true,
      );
    }
  }

  Future<bool> hasUnsynedEntries() async {
    return OfflineStorageService.hasPendingEntries();
  }

  Future<void> syncPendingEntries() async {
    final entries = await OfflineStorageService.getPendingEntries();
    
    for (final entry in entries) {
      try {
        await saveEntry(
          projectId: entry['projectId'],
          logId: entry['logId'],
          logType: entry['data']['logType'],
          hour: entry['data']['hour'],
          data: Map<String, dynamic>.from(entry['data']),
          merge: true,
        );

        // If save successful, delete from offline storage
        await OfflineStorageService.deletePendingEntry(
          projectId: entry['projectId'],
          logId: entry['logId'],
          hour: entry['hour'],
        );
      } catch (e) {
        // If error is not a SaveException with isOfflineSaved,
        // something went wrong with the sync
        if (e is! SaveException || !e.isOfflineSaved) {
          debugPrint('Error syncing entry: $e');
        }
      }
    }
  }
}

class ValidationException implements Exception {
  final Map<String, String> errors;

  ValidationException(this.errors);

  @override
  String toString() => 'Validation failed: ${errors.values.join(', ')}';
}

class SaveException implements Exception {
  final String message;
  final bool isOfflineSaved;

  SaveException(this.message, {this.isOfflineSaved = false});

  @override
  String toString() => message;
}