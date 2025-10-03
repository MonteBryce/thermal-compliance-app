import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/hive_models.dart';

class DailyLogList extends StatelessWidget {
  final List<LogEntry> logEntries;
  final bool isFinalized;
  final Function(LogEntry) onEditEntry;

  const DailyLogList({
    Key? key,
    required this.logEntries,
    required this.isFinalized,
    required this.onEditEntry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (logEntries.isEmpty) {
      return const Center(
        child: Text('No log entries for this day'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logEntries.length,
      itemBuilder: (context, index) {
        final entry = logEntries[index];
        return _LogEntryCard(
          entry: entry,
          isFinalized: isFinalized,
          onEdit: () => onEditEntry(entry),
        );
      },
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  final LogEntry entry;
  final bool isFinalized;
  final VoidCallback onEdit;

  const _LogEntryCard({
    required this.entry,
    required this.isFinalized,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Parse hour to display time
    
    // Parse hour to display time
    String displayTime = entry.hour;
    try {
      final hour = int.parse(entry.hour);
      displayTime = '${hour.toString().padLeft(2, '0')}:00';
    } catch (e) {
      // If parsing fails, use the original hour value
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isFinalized ? null : onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with time and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayTime,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.projectName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _StatusChip(status: entry.status),
                      if (!entry.isSynced) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.sync_problem,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                      ],
                      if (!isFinalized) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Data preview
              if (entry.data.isNotEmpty) _buildDataPreview(context, entry.data),
              
              const SizedBox(height: 8),
              
              // Footer with timestamps
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${DateFormat('MMM d, HH:mm').format(entry.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (entry.updatedAt != entry.createdAt)
                    Text(
                      'Updated: ${DateFormat('MMM d, HH:mm').format(entry.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataPreview(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    
    // Show first 3 data entries as a preview
    final previewEntries = data.entries.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...previewEntries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatFieldName(entry.key),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    _formatFieldValue(entry.value),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
          if (data.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '... and ${data.length - 3} more fields',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatFieldName(String key) {
    // Convert camelCase or snake_case to readable format
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ')
        .trim();
  }

  String _formatFieldValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) {
      if (value is double) {
        return value.toStringAsFixed(2);
      }
      return value.toString();
    }
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    return value.toString();
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String displayText;
    
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        displayText = 'Complete';
        break;
      case 'pending':
        color = Colors.orange;
        displayText = 'Pending';
        break;
      case 'in_progress':
        color = Colors.blue;
        displayText = 'In Progress';
        break;
      case 'draft':
        color = Colors.grey;
        displayText = 'Draft';
        break;
      default:
        color = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}