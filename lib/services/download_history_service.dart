import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Model for tracking download history
class DownloadHistoryEntry {
  final String id;
  final String fileName;
  final String projectId;
  final String projectName;
  final String reportType;
  final DateTime downloadedAt;
  final String downloadedBy;
  final int fileSizeBytes;
  final Map<String, dynamic> metadata;

  DownloadHistoryEntry({
    required this.id,
    required this.fileName,
    required this.projectId,
    required this.projectName,
    required this.reportType,
    required this.downloadedAt,
    required this.downloadedBy,
    required this.fileSizeBytes,
    this.metadata = const {},
  });

  factory DownloadHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DownloadHistoryEntry(
      id: doc.id,
      fileName: data['fileName'] ?? '',
      projectId: data['projectId'] ?? '',
      projectName: data['projectName'] ?? '',
      reportType: data['reportType'] ?? 'unknown',
      downloadedAt: (data['downloadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      downloadedBy: data['downloadedBy'] ?? 'unknown',
      fileSizeBytes: data['fileSizeBytes'] ?? 0,
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fileName': fileName,
      'projectId': projectId,
      'projectName': projectName,
      'reportType': reportType,
      'downloadedAt': Timestamp.fromDate(downloadedAt),
      'downloadedBy': downloadedBy,
      'fileSizeBytes': fileSizeBytes,
      'metadata': metadata,
    };
  }

  String get formattedDownloadDate => DateFormat('MMM dd, yyyy HH:mm').format(downloadedAt);
  String get formattedFileSize => _formatFileSize(fileSizeBytes);

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Service for managing Excel export download history
class DownloadHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'downloadHistory';

  /// Record a new download in the history
  Future<void> recordDownload({
    required String fileName,
    required String projectId,
    required String projectName,
    required String reportType,
    required int fileSizeBytes,
    String? downloadedBy,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection(_collectionName).add({
        'fileName': fileName,
        'projectId': projectId,
        'projectName': projectName,
        'reportType': reportType,
        'downloadedAt': FieldValue.serverTimestamp(),
        'downloadedBy': downloadedBy ?? 'admin',
        'fileSizeBytes': fileSizeBytes,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      print('Error recording download: $e');
      // Continue execution even if logging fails
    }
  }

  /// Get download history stream
  Stream<List<DownloadHistoryEntry>> getDownloadHistoryStream({
    int limit = 50,
    String? projectId,
  }) {
    Query query = _firestore
        .collection(_collectionName)
        .orderBy('downloadedAt', descending: true)
        .limit(limit);

    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }

    return query.snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => DownloadHistoryEntry.fromFirestore(doc)).toList());
  }

  /// Get download history for a specific project
  Future<List<DownloadHistoryEntry>> getProjectDownloadHistory(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('projectId', isEqualTo: projectId)
          .orderBy('downloadedAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => DownloadHistoryEntry.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting project download history: $e');
      return [];
    }
  }

  /// Get download statistics
  Future<DownloadStats> getDownloadStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Get all downloads from the past month for stats
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('downloadedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get();

      final downloads = snapshot.docs.map((doc) => DownloadHistoryEntry.fromFirestore(doc)).toList();

      // Calculate stats
      final totalDownloads = downloads.length;
      final todayDownloads = downloads.where((d) => d.downloadedAt.isAfter(todayStart)).length;
      final weekDownloads = downloads.where((d) => d.downloadedAt.isAfter(weekStart)).length;
      final monthDownloads = downloads.length;

      final totalSizeBytes = downloads.fold<int>(0, (sum, d) => sum + d.fileSizeBytes);

      // Most downloaded project
      final projectCounts = <String, int>{};
      for (final download in downloads) {
        projectCounts[download.projectId] = (projectCounts[download.projectId] ?? 0) + 1;
      }
      
      String? mostDownloadedProject;
      int maxDownloads = 0;
      for (final entry in projectCounts.entries) {
        if (entry.value > maxDownloads) {
          maxDownloads = entry.value;
          mostDownloadedProject = entry.key;
        }
      }

      // Report type breakdown
      final reportTypes = <String, int>{};
      for (final download in downloads) {
        reportTypes[download.reportType] = (reportTypes[download.reportType] ?? 0) + 1;
      }

      return DownloadStats(
        totalDownloads: totalDownloads,
        todayDownloads: todayDownloads,
        weekDownloads: weekDownloads,
        monthDownloads: monthDownloads,
        totalSizeBytes: totalSizeBytes,
        mostDownloadedProject: mostDownloadedProject,
        reportTypeBreakdown: reportTypes,
      );
    } catch (e) {
      print('Error getting download stats: $e');
      return DownloadStats.empty();
    }
  }

  /// Clear download history older than specified days
  Future<void> cleanupOldDownloads({int olderThanDays = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('downloadedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Cleaned up ${snapshot.docs.length} old download records');
    } catch (e) {
      print('Error cleaning up old downloads: $e');
    }
  }

  /// Delete a specific download record
  Future<void> deleteDownloadRecord(String downloadId) async {
    try {
      await _firestore.collection(_collectionName).doc(downloadId).delete();
    } catch (e) {
      print('Error deleting download record: $e');
    }
  }
}

/// Statistics about downloads
class DownloadStats {
  final int totalDownloads;
  final int todayDownloads;
  final int weekDownloads;
  final int monthDownloads;
  final int totalSizeBytes;
  final String? mostDownloadedProject;
  final Map<String, int> reportTypeBreakdown;

  DownloadStats({
    required this.totalDownloads,
    required this.todayDownloads,
    required this.weekDownloads,
    required this.monthDownloads,
    required this.totalSizeBytes,
    this.mostDownloadedProject,
    required this.reportTypeBreakdown,
  });

  factory DownloadStats.empty() {
    return DownloadStats(
      totalDownloads: 0,
      todayDownloads: 0,
      weekDownloads: 0,
      monthDownloads: 0,
      totalSizeBytes: 0,
      mostDownloadedProject: null,
      reportTypeBreakdown: {},
    );
  }

  String get formattedTotalSize => DownloadHistoryEntry._formatFileSize(totalSizeBytes);
}