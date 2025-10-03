import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/date_provider.dart';

/// Widget that displays project start date information with fallback indication
class ProjectStartDateInfo extends ConsumerWidget {
  final String projectId;
  final bool showFallbackInfo;

  const ProjectStartDateInfo({
    super.key,
    required this.projectId,
    this.showFallbackInfo = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectSummaryAsync = ref.watch(projectSummaryProvider(projectId));

    return projectSummaryAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading project information...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to load project information',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (summary) {
        final startDate = summary['startDate'] as DateTime?;
        final hasExplicitStartDate = summary['hasExplicitStartDate'] as bool;
        final calculatedFromLogs = summary['calculatedFromLogs'] as bool;
        final totalLogs = summary['totalLogs'] as int;
        final projectDurationDays = summary['projectDurationDays'] as int?;

        if (startDate == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No project start date available. Create your first log entry to establish a start date.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Project Start Date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Start date display
                Row(
                  children: [
                    const SizedBox(width: 32), // Align with icon
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(startDate),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                if (showFallbackInfo) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 32), // Align with icon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: calculatedFromLogs 
                              ? Colors.orange[100] 
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: calculatedFromLogs 
                                ? Colors.orange[300]! 
                                : Colors.green[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              calculatedFromLogs 
                                  ? Icons.auto_fix_high 
                                  : Icons.check_circle_outline,
                              size: 14,
                              color: calculatedFromLogs 
                                  ? Colors.orange[700] 
                                  : Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              calculatedFromLogs 
                                  ? 'Auto-calculated from first log entry'
                                  : 'Explicitly set',
                              style: TextStyle(
                                fontSize: 12,
                                color: calculatedFromLogs 
                                    ? Colors.orange[700] 
                                    : Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Additional project stats
                if (projectDurationDays != null || totalLogs > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (projectDurationDays != null) ...[
                        Icon(Icons.timeline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '$projectDurationDays days',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (projectDurationDays != null && totalLogs > 0)
                        const SizedBox(width: 16),
                      if (totalLogs > 0) ...[
                        Icon(Icons.folder, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '$totalLogs ${totalLogs == 1 ? 'log' : 'logs'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}