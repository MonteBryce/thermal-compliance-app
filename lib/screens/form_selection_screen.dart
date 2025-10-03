import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/log_template.dart';
import '../services/form_state_service.dart';
import '../services/auth_service.dart';
import '../widgets/form_resume_dialog.dart';

class FormSelectionScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final DateTime selectedDate;

  const FormSelectionScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
    required this.selectedDate,
  }) : super(key: key);

  @override
  ConsumerState<FormSelectionScreen> createState() => _FormSelectionScreenState();
}

class _FormSelectionScreenState extends ConsumerState<FormSelectionScreen> {
  List<FormResumeInfo> _drafts = [];
  bool _isLoadingDrafts = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _isLoadingDrafts = true);
    
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      final drafts = <FormResumeInfo>[];

      for (final formType in ['hourly', 'dailymetrics']) {
        if (formType == 'hourly') {
          for (int hour = 1; hour <= 24; hour++) {
            final resumeInfo = await FormStateService.getResumeInfo(
              projectId: widget.projectId,
              date: dateString,
              formType: formType,
              hour: hour,
            );
            if (resumeInfo != null && resumeInfo.canResume) {
              drafts.add(resumeInfo);
            }
          }
        } else {
          final resumeInfo = await FormStateService.getResumeInfo(
            projectId: widget.projectId,
            date: dateString,
            formType: formType,
          );
          if (resumeInfo != null && resumeInfo.canResume) {
            drafts.add(resumeInfo);
          }
        }
      }

      setState(() {
        _drafts = drafts;
        _isLoadingDrafts = false;
      });
    } catch (e) {
      debugPrint('Failed to load drafts: $e');
      setState(() => _isLoadingDrafts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Form Type'),
            Text(
              '${widget.projectName} - ${dateFormat.format(widget.selectedDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_drafts.isNotEmpty) ...[
            _buildDraftsSection(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
          ],
          
          _buildFormOptionsSection(),
        ],
      ),
    );
  }

  Widget _buildDraftsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.drafts,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Resume Drafts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'You have ${_drafts.length} saved draft${_drafts.length == 1 ? '' : 's'} for this date.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingDrafts)
          const Center(child: CircularProgressIndicator())
        else
          ..._drafts.map((draft) => DraftEntryCard(
            resumeInfo: draft,
            formType: _getFormTypeFromDraftId(draft.draftId),
            projectName: widget.projectName,
            onResume: () => _resumeDraft(draft),
            onDelete: () => _deleteDraft(draft.draftId),
          )),
      ],
    );
  }

  Widget _buildFormOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Create New Form',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        _buildFormOption(
          icon: Icons.schedule,
          title: 'Hourly Readings',
          subtitle: 'Record hourly temperature and system readings',
          color: Colors.blue,
          onTap: () => _showHourSelectionDialog(),
        ),
        
        const SizedBox(height: 12),
        
        _buildFormOption(
          icon: Icons.analytics,
          title: 'Daily System Metrics',
          subtitle: 'Record daily totals and system performance',
          color: Colors.green,
          onTap: () => _navigateToDailyMetrics(),
        ),
      ],
    );
  }

  Widget _buildFormOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _showHourSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Hour'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 24,
            itemBuilder: (context, index) {
              final hour = index + 1;
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToHourlyForm(hour);
                },
                child: Text('$hour'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToHourlyForm(int hour) async {
    final dateString = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    
    final resumeInfo = await FormStateService.getResumeInfo(
      projectId: widget.projectId,
      date: dateString,
      formType: 'hourly',
      hour: hour,
    );

    if (resumeInfo != null && resumeInfo.canResume && context.mounted) {
      FormResumeDialog.show(
        context: context,
        resumeInfo: resumeInfo,
        onResume: () => _openHourlyForm(hour, resumeInfo.draftId),
        onStartFresh: () => _openHourlyForm(hour, null),
      );
    } else {
      _openHourlyForm(hour, null);
    }
  }

  Future<void> _navigateToDailyMetrics() async {
    final dateString = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    
    final resumeInfo = await FormStateService.getResumeInfo(
      projectId: widget.projectId,
      date: dateString,
      formType: 'dailymetrics',
    );

    if (resumeInfo != null && resumeInfo.canResume && context.mounted) {
      FormResumeDialog.show(
        context: context,
        resumeInfo: resumeInfo,
        onResume: () => _openDailyMetricsForm(resumeInfo.draftId),
        onStartFresh: () => _openDailyMetricsForm(null),
      );
    } else {
      _openDailyMetricsForm(null);
    }
  }

  void _openHourlyForm(int hour, String? existingEntryId) {
    context.push('/enhanced-data-entry', extra: {
      'projectId': widget.projectId,
      'projectName': widget.projectName,
      'selectedDate': widget.selectedDate,
      'hour': hour,
      'logType': LogType.hourlyReading,
      'existingEntryId': existingEntryId,
    });
  }

  void _openDailyMetricsForm(String? existingEntryId) {
    context.push('/daily-metrics', extra: {
      'projectId': widget.projectId,
      'projectName': widget.projectName,
      'selectedDate': widget.selectedDate,
      'existingEntryId': existingEntryId,
    });
  }

  void _resumeDraft(FormResumeInfo draft) {
    final draftId = draft.draftId;
    
    if (draftId.contains('hourly')) {
      final hourMatch = RegExp(r'hour_(\d+)').firstMatch(draftId);
      if (hourMatch != null) {
        final hour = int.parse(hourMatch.group(1)!);
        _openHourlyForm(hour, draftId);
      }
    } else if (draftId.contains('dailymetrics')) {
      _openDailyMetricsForm(draftId);
    }
  }

  Future<void> _deleteDraft(String draftId) async {
    try {
      await FormStateService.deleteDraft(draftId);
      _loadDrafts(); // Reload the drafts list
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft deleted successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete draft: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFormTypeFromDraftId(String draftId) {
    if (draftId.contains('hourly')) return 'hourly';
    if (draftId.contains('dailymetrics')) return 'dailymetrics';
    return 'unknown';
  }
}