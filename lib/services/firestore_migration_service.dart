import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/firestore_models.dart';
import 'path_helper.dart';
import 'log_completion_service.dart';

/// Service for migrating existing Firestore data to the new structured model
class FirestoreMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LogCompletionService _logCompletionService = LogCompletionService();

  /// Migrate a single project to the new data structure
  Future<void> migrateProject(String projectId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to perform migration');
    }

    try {
      print('🔄 Starting migration for project: $projectId');

      // Get all log documents for this project
      final logsSnapshot = await FirestoreQueries.projectLogs(projectId).get();
      
      int migratedLogs = 0;
      int migratedEntries = 0;

      for (final logDoc in logsSnapshot.docs) {
        final logId = logDoc.id;
        print('  📂 Migrating log: $logId');

        // Get all entries for this log
        final entriesSnapshot = await FirestoreQueries.logEntries(projectId, logId).get();
        
        // Migrate each entry to the new structure
        for (final entryDoc in entriesSnapshot.docs) {
          await _migrateLogEntry(projectId, logId, entryDoc);
          migratedEntries++;
        }

        // Update or create the log document with completion status
        await _logCompletionService.updateLogCompletionStatus(
          projectId: projectId,
          logId: logId,
        );
        
        migratedLogs++;
        print('  ✅ Migrated log $logId with ${entriesSnapshot.docs.length} entries');
      }

      print('✅ Migration completed for project $projectId');
      print('   📊 Migrated $migratedLogs logs and $migratedEntries entries');
    } catch (e) {
      print('❌ Migration failed for project $projectId: $e');
      rethrow;
    }
  }

  /// Migrate a single log entry to the new structure
  Future<void> _migrateLogEntry(
    String projectId,
    String logId,
    QueryDocumentSnapshot<Map<String, dynamic>> entryDoc,
  ) async {
    try {
      final data = entryDoc.data();
      final entryId = entryDoc.id;

      // Check if already migrated (has 'readings' field with structured data)
      if (data.containsKey('readings') && data['readings'] is Map) {
        print('    ⏭️  Entry $entryId already migrated, skipping');
        return;
      }

      // Extract readings from flat structure
      final readings = _extractReadingsFromLegacyFormat(data);

      // Create structured update
      final updateData = <String, dynamic>{
        'readings': readings,
        'entryType': 'thermal', // Default to thermal for existing entries
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add missing fields if they don't exist
      if (!data.containsKey('createdAt')) {
        updateData['createdAt'] = FieldValue.serverTimestamp();
      }
      
      if (!data.containsKey('createdBy')) {
        updateData['createdBy'] = _auth.currentUser?.uid ?? 'migration';
      }

      if (!data.containsKey('synced')) {
        updateData['synced'] = true;
      }

      if (!data.containsKey('metadata')) {
        updateData['metadata'] = <String, dynamic>{};
      }

      // Update the document
      await FirestoreQueries.logEntry(projectId, logId, entryId)
          .update(updateData);

      print('    ✅ Migrated entry $entryId');
    } catch (e) {
      print('    ❌ Failed to migrate entry ${entryDoc.id}: $e');
      // Continue with other entries even if one fails
    }
  }

  /// Migrate all projects for the current user
  Future<void> migrateAllUserProjects() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to perform migration');
    }

    try {
      print('🔄 Starting migration for all user projects');

      // Get all projects created by or accessible to this user
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      print('📂 Found ${projectsSnapshot.docs.length} projects to migrate');

      for (final projectDoc in projectsSnapshot.docs) {
        await migrateProject(projectDoc.id);
      }

      print('✅ Migration completed for all user projects');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Check migration status for a project
  Future<Map<String, dynamic>> checkMigrationStatus(String projectId) async {
    try {
      final logsSnapshot = await FirestoreQueries.projectLogs(projectId).get();
      
      int totalLogs = logsSnapshot.docs.length;
      int migratedLogs = 0;
      int totalEntries = 0;
      int migratedEntries = 0;

      for (final logDoc in logsSnapshot.docs) {
        final logData = logDoc.data();
        final hasCompletionStatus = logData.containsKey('completionStatus');
        
        if (hasCompletionStatus) {
          migratedLogs++;
        }

        // Check entries
        final entriesSnapshot = await FirestoreQueries.logEntries(projectId, logDoc.id).get();
        totalEntries += entriesSnapshot.docs.length;

        for (final entryDoc in entriesSnapshot.docs) {
          final entryData = entryDoc.data();
          final hasStructuredReadings = entryData.containsKey('readings') && 
                                       entryData['readings'] is Map;
          
          if (hasStructuredReadings) {
            migratedEntries++;
          }
        }
      }

      return {
        'totalLogs': totalLogs,
        'migratedLogs': migratedLogs,
        'totalEntries': totalEntries,
        'migratedEntries': migratedEntries,
        'logsMigrationPercentage': totalLogs > 0 ? (migratedLogs / totalLogs * 100) : 100,
        'entriesMigrationPercentage': totalEntries > 0 ? (migratedEntries / totalEntries * 100) : 100,
        'fullyMigrated': migratedLogs == totalLogs && migratedEntries == totalEntries,
      };
    } catch (e) {
      throw Exception('Failed to check migration status: $e');
    }
  }

  /// Rollback migration (restore flat structure) - for testing/debugging
  Future<void> rollbackProjectMigration(String projectId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to perform rollback');
    }

    try {
      print('🔄 Rolling back migration for project: $projectId');

      final logsSnapshot = await FirestoreQueries.projectLogs(projectId).get();
      
      for (final logDoc in logsSnapshot.docs) {
        final logId = logDoc.id;
        
        // Get all entries for this log
        final entriesSnapshot = await FirestoreQueries.logEntries(projectId, logId).get();
        
        for (final entryDoc in entriesSnapshot.docs) {
          final data = entryDoc.data();
          
          if (data.containsKey('readings') && data['readings'] is Map) {
            final readings = data['readings'] as Map<String, dynamic>;
            final updateData = Map<String, dynamic>.from(data);
            
            // Move readings back to flat structure
            updateData.addAll(readings);
            updateData.remove('readings');
            updateData.remove('entryType');
            
            await FirestoreQueries.logEntry(projectId, logId, entryDoc.id)
                .set(updateData);
          }
        }

        // Remove completion status fields from log document
        await FirestoreQueries.projectLogs(projectId).doc(logId).update({
          'completionStatus': FieldValue.delete(),
          'totalEntries': FieldValue.delete(),
          'completedHours': FieldValue.delete(),
          'validatedHours': FieldValue.delete(),
          'dailyMetrics': FieldValue.delete(),
          'operatorIds': FieldValue.delete(),
        });
      }

      print('✅ Rollback completed for project: $projectId');
    } catch (e) {
      print('❌ Rollback failed for project $projectId: $e');
      rethrow;
    }
  }

  /// Dry run migration - check what would be migrated without making changes
  Future<Map<String, dynamic>> dryRunMigration(String projectId) async {
    try {
      final logsSnapshot = await FirestoreQueries.projectLogs(projectId).get();
      
      final results = <String, dynamic>{
        'projectId': projectId,
        'totalLogs': logsSnapshot.docs.length,
        'logsToMigrate': [],
        'entriesToMigrate': 0,
        'alreadyMigrated': 0,
      };

      for (final logDoc in logsSnapshot.docs) {
        final logId = logDoc.id;
        final logData = logDoc.data();
        
        final entriesSnapshot = await FirestoreQueries.logEntries(projectId, logId).get();
        
        int entriesToMigrate = 0;
        int alreadyMigrated = 0;

        for (final entryDoc in entriesSnapshot.docs) {
          final entryData = entryDoc.data();
          final hasStructuredReadings = entryData.containsKey('readings') && 
                                       entryData['readings'] is Map;
          
          if (hasStructuredReadings) {
            alreadyMigrated++;
          } else {
            entriesToMigrate++;
          }
        }

        if (entriesToMigrate > 0 || !logData.containsKey('completionStatus')) {
          (results['logsToMigrate'] as List).add({
            'logId': logId,
            'totalEntries': entriesSnapshot.docs.length,
            'entriesToMigrate': entriesToMigrate,
            'alreadyMigrated': alreadyMigrated,
            'needsLogDocumentUpdate': !logData.containsKey('completionStatus'),
          });
        }

        results['entriesToMigrate'] = (results['entriesToMigrate'] as int) + entriesToMigrate;
        results['alreadyMigrated'] = (results['alreadyMigrated'] as int) + alreadyMigrated;
      }

      return results;
    } catch (e) {
      throw Exception('Failed to perform dry run migration: $e');
    }
  }

  /// Helper method to extract readings from legacy flat format
  Map<String, dynamic> _extractReadingsFromLegacyFormat(Map<String, dynamic> data) {
    final readings = <String, dynamic>{};
    
    // List of known reading fields from the existing ThermalReading model
    final readingFields = [
      'inletReading',
      'outletReading',
      'toInletReadingH2S',
      'vaporInletFlowRateFPM',
      'vaporInletFlowRateBBL',
      'tankRefillFlowRate',
      'combustionAirFlowRate',
      'vacuumAtTankVaporOutlet',
      'exhaustTemperature',
      'totalizer',
    ];

    for (final field in readingFields) {
      if (data.containsKey(field) && data[field] != null) {
        readings[field] = data[field];
      }
    }

    return readings;
  }
}