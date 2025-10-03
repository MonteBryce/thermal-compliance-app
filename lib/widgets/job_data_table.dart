/// Job Data Table Widget
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/job_dashboard_models.dart';
import 'operator_badge.dart';
import 'metric_status_cell.dart';

class JobDataTable extends StatelessWidget {
  final List<JobDashboardData> jobs;
  final Function(JobDashboardData)? onViewJob;
  final Function(JobDashboardData)? onAssignJob;
  final Function(JobDashboardData)? onExportJob;
  final Function(JobDashboardData)? onEditJob;
  final Function(JobDashboardData)? onArchiveJob;

  const JobDataTable({
    super.key,
    required this.jobs,
    this.onViewJob,
    this.onAssignJob,
    this.onExportJob,
    this.onEditJob,
    this.onArchiveJob,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _buildHeaderCell('Project Name', width: 180),
                _buildHeaderCell('Facility', width: 120),
                _buildHeaderCell('Type', width: 120),
                _buildHeaderCell('Date Range', width: 100),
                _buildHeaderCell('Progress', width: 140),
                _buildHeaderCell('System Status', width: 180),
                _buildHeaderCell('Priority', width: 100),
                _buildHeaderCell('Operators', width: 120),
                _buildHeaderCell('Status', width: 100),
                _buildHeaderCell('Actions', width: 80),
              ],
            ),
          ),
          
          // Table Body
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1240, // Fixed total width
                child: ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final isEven = index % 2 == 0;
                    
                    return Container(
                      height: 60,
                      constraints: const BoxConstraints(
                        minHeight: 60,
                        maxHeight: 60,
                      ),
                      decoration: BoxDecoration(
                        color: isEven 
                            ? const Color(0xFF1E1E1E) 
                            : const Color(0xFF191919),
                      ),
                      child: Row(
                        children: [
                          _buildDataCell(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  job.projectName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            width: 180,
                          ),
                          
                          _buildDataCell(
                            child: Text(
                              job.facility,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFE5E5E5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            width: 120,
                          ),
                          
                          _buildDataCell(
                            child: _buildProjectTypeBadge(job.projectType),
                            width: 120,
                          ),
                          
                          _buildDataCell(
                            child: Text(
                              job.dateRange,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFE5E5E5),
                              ),
                            ),
                            width: 100,
                          ),
                          
                          _buildDataCell(
                            child: _buildProgressCell(job.hoursLogged, job.totalHours, job.estimatedCompletion),
                            width: 140,
                          ),
                          
                          _buildDataCell(
                            child: MetricStatusCell(
                              dailyMetrics: job.systemMetrics,
                              daysToShow: 7,
                            ),
                            width: 180,
                          ),
                          
                          _buildDataCell(
                            child: _buildPriorityBadge(job.priority),
                            width: 100,
                          ),
                          
                          _buildDataCell(
                            child: SizedBox(
                              width: 100,
                              child: OperatorPillGroup(
                                operators: job.assignedOperators,
                                maxVisible: 2,
                                badgeSize: 24,
                              ),
                            ),
                            width: 120,
                          ),
                          
                          _buildDataCell(
                            child: _buildStatusBadge(job.status),
                            width: 100,
                          ),
                          
                          _buildDataCell(
                            child: _buildActionButtons(job),
                            width: 80,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  Widget _buildDataCell({required Widget child, double? width}) {
    return Container(
      width: width,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Widget _buildProjectTypeBadge(String projectType) {
    Color color;
    switch (projectType.toLowerCase()) {
      case 'tank inspection':
        color = const Color(0xFF3B82F6);
        break;
      case 'safety inspection':
        color = const Color(0xFFEF4444);
        break;
      case 'system upgrade':
        color = const Color(0xFF10B981);
        break;
      case 'environmental':
        color = const Color(0xFF059669);
        break;
      case 'safety training':
        color = const Color(0xFFF59E0B);
        break;
      case 'maintenance':
        color = const Color(0xFF8B5CF6);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        projectType,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildProgressCell(int hoursLogged, int totalHours, double estimatedCompletion) {
    final percentage = estimatedCompletion;
    
    return SizedBox(
      width: 120,
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${hoursLogged}h/${totalHours}h',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (percentage / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: percentage >= 80 
                      ? const Color(0xFF10B981)
                      : percentage >= 50
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'critical':
        color = const Color(0xFFEF4444);
        break;
      case 'high':
        color = const Color(0xFFF59E0B);
        break;
      case 'medium':
        color = const Color(0xFF3B82F6);
        break;
      case 'low':
        color = const Color(0xFF10B981);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        priority,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = const Color(0xFF10B981);
        break;
      case 'pending review':
        color = const Color(0xFFF59E0B);
        break;
      case 'complete':
        color = const Color(0xFF3B82F6);
        break;
      case 'on hold':
        color = const Color(0xFF6B7280);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionButtons(JobDashboardData job) {
    return Tooltip(
      message: 'More actions',
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert,
          color: Color(0xFF9CA3AF),
          size: 18,
        ),
        color: const Color(0xFF1E1E1E),
        itemBuilder: (context) => [
          _buildMenuItem('view', Icons.visibility, 'View Details'),
          _buildMenuItem('assign', Icons.person_add, 'Assign Team'),
          _buildMenuItem('export', Icons.download, 'Export Data'),
          const PopupMenuDivider(color: Color(0xFF2A2A2A)),
          _buildMenuItem('edit', Icons.edit, 'Edit Job'),
          _buildMenuItem('archive', Icons.archive, 'Archive'),
        ],
        onSelected: (value) {
          switch (value) {
            case 'view':
              onViewJob?.call(job);
              break;
            case 'assign':
              onAssignJob?.call(job);
              break;
            case 'export':
              onExportJob?.call(job);
              break;
            case 'edit':
              onEditJob?.call(job);
              break;
            case 'archive':
              onArchiveJob?.call(job);
              break;
          }
        },
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
