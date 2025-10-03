import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/form_state_service.dart';

class FormResumeDialog extends StatelessWidget {
  final FormResumeInfo resumeInfo;
  final VoidCallback onResume;
  final VoidCallback onStartFresh;

  const FormResumeDialog({
    Key? key,
    required this.resumeInfo,
    required this.onResume,
    required this.onStartFresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.restore,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Resume Form?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We found a saved draft of this form from ${resumeInfo.formattedLastModified}.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${resumeInfo.completedFields}/${resumeInfo.totalFields} fields',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: resumeInfo.completionPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    resumeInfo.completionPercentage > 0.7 
                        ? Colors.green 
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(resumeInfo.completionPercentage * 100).toStringAsFixed(0)}% complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Text(
            'Would you like to continue where you left off or start fresh?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onStartFresh();
          },
          child: const Text('Start Fresh'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onResume();
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Resume'),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required FormResumeInfo resumeInfo,
    required VoidCallback onResume,
    required VoidCallback onStartFresh,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FormResumeDialog(
        resumeInfo: resumeInfo,
        onResume: onResume,
        onStartFresh: onStartFresh,
      ),
    );
  }
}

class DraftEntryCard extends StatelessWidget {
  final FormResumeInfo resumeInfo;
  final String formType;
  final String projectName;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  const DraftEntryCard({
    Key? key,
    required this.resumeInfo,
    required this.formType,
    required this.projectName,
    required this.onResume,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _getFormIcon(),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          _getFormDisplayName(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(projectName),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${(resumeInfo.completionPercentage * 100).toStringAsFixed(0)}% complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${resumeInfo.formattedLastModified}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: resumeInfo.completionPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                resumeInfo.completionPercentage > 0.7 
                    ? Colors.green 
                    : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'resume',
              child: Row(
                children: const [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Resume'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'resume':
                onResume();
                break;
              case 'delete':
                _showDeleteConfirmation(context);
                break;
            }
          },
        ),
        onTap: onResume,
      ),
    );
  }

  IconData _getFormIcon() {
    switch (formType.toLowerCase()) {
      case 'hourly':
        return Icons.schedule;
      case 'daily':
      case 'dailymetrics':
        return Icons.analytics;
      default:
        return Icons.description;
    }
  }

  String _getFormDisplayName() {
    switch (formType.toLowerCase()) {
      case 'hourly':
        return 'Hourly Reading';
      case 'daily':
      case 'dailymetrics':
        return 'Daily Metrics';
      default:
        return 'Form Draft';
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft'),
        content: const Text(
          'Are you sure you want to delete this draft? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}