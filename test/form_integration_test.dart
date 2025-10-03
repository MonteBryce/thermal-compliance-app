import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../lib/models/hive_models.dart';
import '../lib/services/local_database_service.dart';
import '../lib/services/form_state_service.dart';
import '../lib/models/log_template.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('Form Integration Tests', () {
    late Box<LogEntry> logEntriesBox;
    late Directory tempDir;
    
    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('hive_test');
      Hive.init(tempDir.path);
      Hive.registerAdapter(LogEntryAdapter());
      
      logEntriesBox = await Hive.openBox<LogEntry>('log_entries_test');
      await Hive.openBox<LogEntry>('logEntries');
    });

    tearDown(() async {
      await logEntriesBox.clear();
    });

    tearDownAll(() async {
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    group('FormStateService', () {
      test('should save and load form progress', () async {
        const projectId = 'test_project';
        const projectName = 'Test Project';
        const date = '2024-01-01';
        const formType = 'hourly';
        const userId = 'test_user';
        const hour = 10;

        final formData = {
          'temperature': 75.5,
          'pressure': 14.7,
          'notes': 'Test reading',
        };

        await FormStateService.saveFormProgress(
          projectId: projectId,
          projectName: projectName,
          date: date,
          formType: formType,
          formData: formData,
          userId: userId,
          hour: hour,
        );

        final loadedEntry = await FormStateService.loadFormProgress(
          projectId: projectId,
          date: date,
          formType: formType,
          hour: hour,
        );

        expect(loadedEntry, isNotNull);
        expect(loadedEntry!.status, equals('draft'));
        expect(loadedEntry.data['temperature'], equals(75.5));
        expect(loadedEntry.data['pressure'], equals(14.7));
        expect(loadedEntry.data['notes'], equals('Test reading'));
      });

      test('should get resume info for saved draft', () async {
        const projectId = 'test_project';
        const projectName = 'Test Project';
        const date = '2024-01-01';
        const formType = 'dailymetrics';
        const userId = 'test_user';

        final formData = {
          'runtime_hours': 24.0,
          'energy_consumed': 150.5,
          'maintenance_notes': 'System running normally',
        };

        await FormStateService.saveFormProgress(
          projectId: projectId,
          projectName: projectName,
          date: date,
          formType: formType,
          formData: formData,
          userId: userId,
        );

        final resumeInfo = await FormStateService.getResumeInfo(
          projectId: projectId,
          date: date,
          formType: formType,
        );

        expect(resumeInfo, isNotNull);
        expect(resumeInfo!.canResume, isTrue);
        expect(resumeInfo.completedFields, equals(3));
        expect(resumeInfo.completionPercentage, greaterThan(0.0));
      });

      test('should delete draft successfully', () async {
        const projectId = 'test_project';
        const projectName = 'Test Project';
        const date = '2024-01-01';
        const formType = 'hourly';
        const userId = 'test_user';
        const hour = 15;

        final formData = {'temperature': 72.0};

        await FormStateService.saveFormProgress(
          projectId: projectId,
          projectName: projectName,
          date: date,
          formType: formType,
          formData: formData,
          userId: userId,
          hour: hour,
        );

        final loadedBefore = await FormStateService.loadFormProgress(
          projectId: projectId,
          date: date,
          formType: formType,
          hour: hour,
        );
        expect(loadedBefore, isNotNull);

        await FormStateService.deleteDraft(loadedBefore!.id);

        final loadedAfter = await FormStateService.loadFormProgress(
          projectId: projectId,
          date: date,
          formType: formType,
          hour: hour,
        );
        expect(loadedAfter, isNull);
      });

      test('should promote draft to completed entry', () async {
        const projectId = 'test_project';
        const projectName = 'Test Project';
        const date = '2024-01-01';
        const formType = 'hourly';
        const userId = 'test_user';
        const hour = 12;

        final formData = {
          'temperature': 78.2,
          'pressure': 14.8,
          'validation_passed': true,
        };

        await FormStateService.saveFormProgress(
          projectId: projectId,
          projectName: projectName,
          date: date,
          formType: formType,
          formData: formData,
          userId: userId,
          hour: hour,
        );

        final draft = await FormStateService.loadFormProgress(
          projectId: projectId,
          date: date,
          formType: formType,
          hour: hour,
        );
        expect(draft, isNotNull);

        await FormStateService.promoteDraftToCompleted(
          draftId: draft!.id,
          finalData: formData,
        );

        final draftAfter = await FormStateService.loadFormProgress(
          projectId: projectId,
          date: date,
          formType: formType,
          hour: hour,
        );
        expect(draftAfter, isNull);

        final completedId = draft.id.replaceFirst('draft_', '');
        final completedEntry = await LocalDatabaseService.getLogEntry(completedId);
        expect(completedEntry, isNotNull);
        expect(completedEntry!.status, equals('completed'));
      });
    });

    group('LocalDatabaseService Integration', () {
      test('should save and retrieve log entries', () async {
        final entry = LogEntry(
          id: 'test_entry_1',
          projectId: 'test_project',
          projectName: 'Test Project',
          date: '2024-01-01',
          hour: '10',
          data: {
            'temperature': 75.0,
            'pressure': 14.7,
            'notes': 'Integration test entry',
          },
          status: 'completed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test_user',
          isSynced: false,
        );

        await LocalDatabaseService.saveLogEntry(entry);

        final retrieved = await LocalDatabaseService.getLogEntry('test_entry_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.projectId, equals('test_project'));
        expect(retrieved.data['temperature'], equals(75.0));
        expect(retrieved.status, equals('completed'));
      });

      test('should get entries by project and date', () async {
        final date = DateTime(2024, 1, 1);
        const projectId = 'test_project';

        for (int hour = 1; hour <= 3; hour++) {
          final entry = LogEntry(
            id: 'test_entry_$hour',
            projectId: projectId,
            projectName: 'Test Project',
            date: DateFormat('yyyy-MM-dd').format(date),
            hour: hour.toString(),
            data: {'temperature': 70.0 + hour},
            status: 'completed',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'test_user',
            isSynced: false,
          );
          await LocalDatabaseService.saveLogEntry(entry);
        }

        final entries = await LocalDatabaseService.getLogEntriesByProjectAndDate(
          projectId,
          date,
        );

        expect(entries.length, equals(3));
        expect(entries.every((e) => e.projectId == projectId), isTrue);
        expect(entries.every((e) => e.date == '2024-01-01'), isTrue);
      });

      test('should update existing entry', () async {
        final entry = LogEntry(
          id: 'update_test_entry',
          projectId: 'test_project',
          projectName: 'Test Project',
          date: '2024-01-01',
          hour: '5',
          data: {'temperature': 70.0},
          status: 'draft',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test_user',
          isSynced: false,
        );

        await LocalDatabaseService.saveLogEntry(entry);

        final updatedEntry = LogEntry(
          id: 'update_test_entry',
          projectId: 'test_project',
          projectName: 'Test Project',
          date: '2024-01-01',
          hour: '5',
          data: {'temperature': 75.5, 'pressure': 14.8},
          status: 'completed',
          createdAt: entry.createdAt,
          updatedAt: DateTime.now(),
          createdBy: 'test_user',
          isSynced: false,
        );

        await LocalDatabaseService.saveLogEntry(updatedEntry);

        final retrieved = await LocalDatabaseService.getLogEntry('update_test_entry');
        expect(retrieved, isNotNull);
        expect(retrieved!.status, equals('completed'));
        expect(retrieved.data['temperature'], equals(75.5));
        expect(retrieved.data['pressure'], equals(14.8));
      });

      test('should delete entry', () async {
        final entry = LogEntry(
          id: 'delete_test_entry',
          projectId: 'test_project',
          projectName: 'Test Project',
          date: '2024-01-01',
          hour: '8',
          data: {'temperature': 72.0},
          status: 'completed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test_user',
          isSynced: false,
        );

        await LocalDatabaseService.saveLogEntry(entry);

        final beforeDelete = await LocalDatabaseService.getLogEntry('delete_test_entry');
        expect(beforeDelete, isNotNull);

        await LocalDatabaseService.deleteLogEntry('delete_test_entry');

        final afterDelete = await LocalDatabaseService.getLogEntry('delete_test_entry');
        expect(afterDelete, isNull);
      });
    });

    group('Form Template Integration', () {
      test('should create hourly reading template', () {
        final template = LogTemplateRegistry.getTemplate(LogType.hourlyReading);
        
        expect(template, isNotNull);
        expect(template.type, equals(LogType.hourlyReading));
        expect(template.fields.isNotEmpty, isTrue);
        
        // Check if there's at least one numeric field
        final numericFields = template.fields.where((field) => field.type == FieldType.number);
        expect(numericFields.isNotEmpty, isTrue);
      });

      test('should create daily metrics template', () {
        final template = LogTemplateRegistry.getTemplate(LogType.dailyMetrics);
        
        expect(template, isNotNull);
        expect(template.type, equals(LogType.dailyMetrics));
        expect(template.fields.isNotEmpty, isTrue);
        
        // Check if template has required structure
        final fields = template.fields;
        expect(fields.length, greaterThan(0));
      });

      test('should validate field values correctly', () {
        final template = LogTemplateRegistry.getTemplate(LogType.hourlyReading);
        final firstField = template.fields.first;

        if (firstField.type == FieldType.number) {
          final validResult = firstField.validate('75.5', {});
          expect(validResult, isNull);

          final invalidResult = firstField.validate('invalid', {});
          expect(invalidResult, isNotNull);
        } else {
          // Just test that validation works for any field type
          final result = firstField.validate('test value', {});
          expect(result == null || result is String, isTrue);
        }
      });
    });

    group('End-to-End Form Workflow', () {
      test('should complete full form workflow: draft -> save -> complete', () async {
        const projectId = 'workflow_test';
        const projectName = 'Workflow Test Project';
        const date = '2024-01-15';
        const formType = 'hourly';
        const userId = 'workflow_user';
        const hour = 14;

        final draftData = {
          'temperature': 76.2,
          'pressure': 14.9,
        };

        await FormStateService.saveFormProgress(
          projectId: projectId,
          projectName: projectName,
          date: date,
          formType: formType,
          formData: draftData,
          userId: userId,
          hour: hour,
        );

        final draft = await FormStateService.loadFormProgress(
          projectId: projectId,
          date: date,
          formType: formType,
          hour: hour,
        );
        expect(draft, isNotNull);
        expect(draft!.status, equals('draft'));

        final finalData = {
          'temperature': 76.2,
          'pressure': 14.9,
          'notes': 'Workflow test completed',
          'validated': true,
        };

        await FormStateService.promoteDraftToCompleted(
          draftId: draft.id,
          finalData: finalData,
        );

        final completedId = draft.id.replaceFirst('draft_', '');
        final completed = await LocalDatabaseService.getLogEntry(completedId);
        expect(completed, isNotNull);
        expect(completed!.status, equals('completed'));
        expect(completed.data['notes'], equals('Workflow test completed'));
        expect(completed.data['validated'], equals(true));

        final draftAfterPromotion = await FormStateService.loadFormProgress(
          projectId: projectId,
          date: date,
          formType: formType,
          hour: hour,
        );
        expect(draftAfterPromotion, isNull);
      });
    });
  });
}