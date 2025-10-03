/// System Metrics Status Cell Widget
import 'package:flutter/material.dart';

enum MetricStatus {
  pass,
  warning,
  fail,
  unknown,
}

class MetricStatusCell extends StatelessWidget {
  final List<MetricStatus> dailyMetrics;
  final int daysToShow;

  const MetricStatusCell({
    super.key,
    required this.dailyMetrics,
    this.daysToShow = 7,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172, // 7 icons * 20px + 6 gaps * 4px = 164px + padding
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(daysToShow, (index) {
            final status = index < dailyMetrics.length 
                ? dailyMetrics[index] 
                : MetricStatus.unknown;
            
            return Padding(
              padding: EdgeInsets.only(right: index < daysToShow - 1 ? 4 : 0),
              child: Tooltip(
                message: _getStatusTooltip(status, index),
                child: _buildStatusIcon(status),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(MetricStatus status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case MetricStatus.pass:
        icon = Icons.check_circle;
        color = const Color(0xFF10B981);
        break;
      case MetricStatus.warning:
        icon = Icons.warning;
        color = const Color(0xFFF59E0B);
        break;
      case MetricStatus.fail:
        icon = Icons.cancel;
        color = const Color(0xFFEF4444);
        break;
      case MetricStatus.unknown:
        icon = Icons.help_outline;
        color = const Color(0xFF6B7280);
        break;
    }
    
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 12,
        color: color,
      ),
    );
  }
  
  String _getStatusTooltip(MetricStatus status, int dayIndex) {
    final dayText = 'Day ${dayIndex + 1}';
    switch (status) {
      case MetricStatus.pass:
        return '$dayText: All metrics passed';
      case MetricStatus.warning:
        return '$dayText: Warning - Check required';
      case MetricStatus.fail:
        return '$dayText: Failed - Immediate action needed';
      case MetricStatus.unknown:
        return '$dayText: No data available';
    }
  }
}

class ComplianceStatusBadge extends StatelessWidget {
  final String status;
  final bool isCompliant;

  const ComplianceStatusBadge({
    super.key,
    required this.status,
    required this.isCompliant,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompliant 
        ? const Color(0xFF10B981) 
        : const Color(0xFFEF4444);
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompliant ? Icons.check_circle : Icons.warning,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class TankIdBadge extends StatelessWidget {
  final String tankId;
  final Color? backgroundColor;

  const TankIdBadge({
    super.key,
    required this.tankId,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? const Color(0xFF3B82F6);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        tankId,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
