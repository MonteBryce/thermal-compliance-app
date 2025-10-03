/// Job Table Component for Admin Dashboard
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/admin_dashboard_models.dart';
import '../providers/admin_dashboard_providers.dart';

class JobTable extends ConsumerWidget {
  const JobTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final filteredJobs = ref.watch(filteredJobsProvider);
    final isLoading = ref.watch(adminJobsProvider).isLoading;
    
    if (isLoading) {
      return _buildLoadingState(isDarkMode);
    }
    
    if (filteredJobs.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.table_chart_outlined,
                      size: 20,
                      color: isDarkMode ? Colors.white : const Color(0xFF111827),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Projects',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                
                // Table Actions
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Export to CSV
                      },
                      icon: const Icon(Icons.download_outlined, size: 18),
                      tooltip: 'Export CSV',
                    ),
                    IconButton(
                      onPressed: () {
                        // Refresh data
                        ref.invalidate(adminJobsProvider);
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: DataTable(
                  headingRowHeight: 56,
                  dataRowHeight: 72,
                  headingRowColor: WidgetStateProperty.all(
                    isDarkMode ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
                  ),
                  columnSpacing: 24,
                  columns: [
                    DataColumn(
                      label: Text(
                        'Project',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Log Type',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Operator',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Progress',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Last Activity',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Actions',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                  rows: filteredJobs.map((job) => _buildDataRow(job, isDarkMode, context)).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(AdminJob job, bool isDarkMode, BuildContext context) {
    return DataRow(
      cells: [
        // Project Name & Location
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                job.projectName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                job.location,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        
        // Status Badge
        DataCell(
          _buildStatusBadge(job.status, job.isOverdue),
        ),
        
        // Log Type
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatLogType(job.logType),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ),
        ),
        
        // Operator
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF3B82F6),
                child: Text(
                  job.assignedOperator.isNotEmpty 
                      ? job.assignedOperator[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                job.assignedOperator,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        
        // Progress
        DataCell(
          _buildProgressIndicator(job.completionPercentage, job.completedLogs, job.totalLogs, isDarkMode),
        ),
        
        // Last Activity
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDate(job.lastActivity),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTimeAgo(job.lastActivity),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        
        // Actions
        DataCell(
          _buildActionButtons(job, context),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(JobStatus status, bool isOverdue) {
    Color backgroundColor;
    Color textColor;
    String displayText = status.displayName;
    
    if (isOverdue) {
      backgroundColor = const Color(0xFFEF4444).withOpacity(0.1);
      textColor = const Color(0xFFEF4444);
      displayText = 'Overdue';
    } else {
      switch (status) {
        case JobStatus.active:
          backgroundColor = const Color(0xFF10B981).withOpacity(0.1);
          textColor = const Color(0xFF10B981);
          break;
        case JobStatus.completed:
          backgroundColor = const Color(0xFF3B82F6).withOpacity(0.1);
          textColor = const Color(0xFF3B82F6);
          break;
        case JobStatus.archived:
          backgroundColor = const Color(0xFF6B7280).withOpacity(0.1);
          textColor = const Color(0xFF6B7280);
          break;
        case JobStatus.paused:
          backgroundColor = const Color(0xFFF59E0B).withOpacity(0.1);
          textColor = const Color(0xFFF59E0B);
          break;
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double percentage, int completed, int total, bool isDarkMode) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : const Color(0xFF111827),
                ),
              ),
              Text(
                '$completed/$total',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 80 
                  ? const Color(0xFF10B981)
                  : percentage >= 50
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AdminJob job, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Logs
        IconButton(
          onPressed: () {
            // Navigate to job logs
          },
          icon: const Icon(Icons.visibility_outlined, size: 18),
          tooltip: 'View Logs',
        ),
        
        // Export
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'export_excel':
                // Export to Excel
                break;
              case 'export_pdf':
                // Export to PDF
                break;
              case 'assign':
                // Assign operator
                break;
              case 'edit':
                // Edit project
                break;
              case 'archive':
                // Archive project
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export_excel',
              child: Row(
                children: [
                  const Icon(Icons.table_chart, size: 16),
                  const SizedBox(width: 8),
                  Text('Export Excel', style: GoogleFonts.inter(fontSize: 14)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export_pdf',
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, size: 16),
                  const SizedBox(width: 8),
                  Text('Export PDF', style: GoogleFonts.inter(fontSize: 14)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'assign',
              child: Row(
                children: [
                  const Icon(Icons.person_add, size: 16),
                  const SizedBox(width: 8),
                  Text('Assign', style: GoogleFonts.inter(fontSize: 14)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16),
                  const SizedBox(width: 8),
                  Text('Edit', style: GoogleFonts.inter(fontSize: 14)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  const Icon(Icons.archive, size: 16),
                  const SizedBox(width: 8),
                  Text('Archive', style: GoogleFonts.inter(fontSize: 14)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.more_vert, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            const SizedBox(height: 16),
            Text(
              'No projects found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or create a new project',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLogType(String logType) {
    return logType.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
