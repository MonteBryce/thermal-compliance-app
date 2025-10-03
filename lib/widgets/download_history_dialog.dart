import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/download_history_service.dart';

/// Dialog for viewing download history
class DownloadHistoryDialog extends StatefulWidget {
  final String? projectId;

  const DownloadHistoryDialog({
    super.key,
    this.projectId,
  });

  @override
  State<DownloadHistoryDialog> createState() => _DownloadHistoryDialogState();
}

class _DownloadHistoryDialogState extends State<DownloadHistoryDialog> {
  final DownloadHistoryService _historyService = DownloadHistoryService();
  late Stream<List<DownloadHistoryEntry>> _historyStream;
  DownloadStats? _stats;

  @override
  void initState() {
    super.initState();
    _historyStream = _historyService.getDownloadHistoryStream(
      projectId: widget.projectId,
    );
    _loadStats();
  }

  void _loadStats() async {
    try {
      final stats = await _historyService.getDownloadStats();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      print('Error loading download stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.projectId != null 
                        ? 'Project Download History' 
                        : 'Download History',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Stats Section
            if (_stats != null && widget.projectId == null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF111111),
                child: _buildStatsSection(),
              ),
            ],

            // History List
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: StreamBuilder<List<DownloadHistoryEntry>>(
                  stream: _historyStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading download history',
                              style: GoogleFonts.inter(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final downloads = snapshot.data ?? [];

                    if (downloads.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.download_outlined,
                              color: Colors.white38,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No downloads yet',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Excel reports you download will appear here',
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildHistoryList(downloads);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_stats == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Downloads',
            _stats!.totalDownloads.toString(),
            Icons.download_outlined,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'This Month',
            _stats!.monthDownloads.toString(),
            Icons.calendar_month,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'This Week',
            _stats!.weekDownloads.toString(),
            Icons.calendar_week,
            const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Size',
            _stats!.formattedTotalSize,
            Icons.storage,
            const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<DownloadHistoryEntry> downloads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Downloads',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              final download = downloads[index];
              return _buildDownloadItem(download);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadItem(DownloadHistoryEntry download) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.table_chart,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // File details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  download.fileName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  download.projectName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildChip(download.reportType, const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text(
                      download.formattedFileSize,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Download info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                download.formattedDownloadDate,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'by ${download.downloadedBy}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70, size: 16),
            color: const Color(0xFF2A2A2A),
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(download);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _confirmDelete(DownloadHistoryEntry download) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Delete Download Record',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this download record?\n\n${download.fileName}',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _historyService.deleteDownloadRecord(download.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Download record deleted'),
                    backgroundColor: Color(0xFF1E1E1E),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(),
            ),
          ),
        ],
      ),
    );
  }
}