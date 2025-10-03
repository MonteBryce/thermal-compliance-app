/// Summary KPI Cards for Admin Dashboard
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/admin_dashboard_models.dart';
import '../providers/admin_dashboard_providers.dart';

class SummaryWidgets extends ConsumerWidget {
  const SummaryWidgets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final summary = ref.watch(dashboardSummaryProvider).value ?? DashboardSummary.empty;
    final jobStats = ref.watch(jobStatisticsProvider);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _getCrossAxisCount(context),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _buildSummaryCard(
          title: 'Active Jobs',
          value: jobStats['active']?.toString() ?? '0',
          subtitle: '${jobStats['total'] ?? 0} total projects',
          icon: Icons.work_outline,
          color: const Color(0xFF3B82F6),
          trend: const _TrendInfo(isPositive: true, percentage: 12),
          isDarkMode: isDarkMode,
        ),
        
        _buildSummaryCard(
          title: 'Completion Rate',
          value: '${summary.completionPercentage.toStringAsFixed(1)}%',
          subtitle: 'Overall progress',
          icon: Icons.trending_up,
          color: const Color(0xFF10B981),
          trend: const _TrendInfo(isPositive: true, percentage: 8),
          isDarkMode: isDarkMode,
        ),
        
        _buildSummaryCard(
          title: 'Total Alerts',
          value: (jobStats['overdue']?.toString() ?? '0'),
          subtitle: 'Requires attention',
          icon: Icons.warning_outlined,
          color: const Color(0xFFF59E0B),
          trend: const _TrendInfo(isPositive: false, percentage: 5),
          isDarkMode: isDarkMode,
        ),
        
        _buildSummaryCard(
          title: 'Total Logs',
          value: _formatNumber(summary.totalLogs),
          subtitle: 'Data entries recorded',
          icon: Icons.description_outlined,
          color: const Color(0xFF8B5CF6),
          trend: const _TrendInfo(isPositive: true, percentage: 15),
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required _TrendInfo trend,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trend.isPositive 
                      ? const Color(0xFF10B981).withOpacity(0.1) 
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend.isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: trend.isPositive 
                          ? const Color(0xFF10B981) 
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trend.percentage}%',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: trend.isPositive 
                            ? const Color(0xFF10B981) 
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Value
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : const Color(0xFF111827),
              height: 1,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : const Color(0xFF111827),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Subtitle
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _TrendInfo {
  final bool isPositive;
  final int percentage;

  const _TrendInfo({
    required this.isPositive,
    required this.percentage,
  });
}
