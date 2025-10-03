import 'package:flutter/material.dart';
import '../model/job_model.dart';
import '../services/excel_template_selection_service.dart';

/// Widget that shows template configuration status for a job
class JobTemplateIndicator extends StatelessWidget {
  final Job job;
  final bool showDetails;
  final VoidCallback? onTap;

  const JobTemplateIndicator({
    super.key,
    required this.job,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!job.hasExcelTemplate) {
      return _buildFlutterFormsIndicator(context);
    }

    return _buildExcelTemplateIndicator(context);
  }

  Widget _buildFlutterFormsIndicator(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: showDetails ? 12 : 8,
          vertical: showDetails ? 8 : 4,
        ),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade200),
          borderRadius: BorderRadius.circular(showDetails ? 8 : 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone_android,
              size: showDetails ? 16 : 12,
              color: Colors.blue.shade700,
            ),
            if (showDetails) ...[
              const SizedBox(width: 6),
              Text(
                'Flutter Forms',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExcelTemplateIndicator(BuildContext context) {
    final templateConfig = job.templateConfig!;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: showDetails ? 12 : 8,
          vertical: showDetails ? 8 : 4,
        ),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(showDetails ? 8 : 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_present,
              size: showDetails ? 16 : 12,
              color: Colors.green.shade700,
            ),
            if (showDetails) ...[
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Excel Export',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                  if (templateConfig.excelTemplateId != null)
                    Text(
                      templateConfig.excelTemplateId!.split('_').first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade600,
                      ),
                    ),
                ],
              ),
              if (templateConfig.autoExportEnabled) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.auto_mode,
                  size: 12,
                  color: Colors.green.shade600,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Enhanced job template status widget with more details
class JobTemplateStatusCard extends StatefulWidget {
  final Job job;
  final VoidCallback? onEditTemplate;

  const JobTemplateStatusCard({
    super.key,
    required this.job,
    this.onEditTemplate,
  });

  @override
  State<JobTemplateStatusCard> createState() => _JobTemplateStatusCardState();
}

class _JobTemplateStatusCardState extends State<JobTemplateStatusCard> {
  final ExcelTemplateSelectionService _templateService = ExcelTemplateSelectionService();
  ExcelTemplateConfig? _templateDetails;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTemplateDetails();
  }

  Future<void> _loadTemplateDetails() async {
    if (!widget.job.hasExcelTemplate) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final templateConfig = widget.job.templateConfig!;
      if (templateConfig.excelTemplateId != null) {
        final template = await _templateService.getTemplateById(templateConfig.excelTemplateId!);
        setState(() {
          _templateDetails = template;
        });
      }
    } catch (e) {
      // Handle error silently for now
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.job.hasExcelTemplate ? Icons.file_present : Icons.phone_android,
                  color: widget.job.hasExcelTemplate ? Colors.green : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Export Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.onEditTemplate != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: widget.onEditTemplate,
                    tooltip: 'Edit template configuration',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Template status
            _buildStatusRow(
              'Export Method',
              widget.job.hasExcelTemplate ? 'Excel Template' : 'Flutter Forms Only',
              widget.job.hasExcelTemplate ? Colors.green : Colors.blue,
            ),

            if (widget.job.hasExcelTemplate) ...[
              const SizedBox(height: 8),
              _buildStatusRow(
                'Log Type',
                widget.job.logTypeEnum.displayName,
                Colors.grey.shade700,
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_templateDetails != null) ...[
                const SizedBox(height: 8),
                _buildStatusRow(
                  'Template',
                  _templateDetails!.displayName,
                  Colors.grey.shade700,
                ),
                const SizedBox(height: 8),
                _buildStatusRow(
                  'Required Fields',
                  '${_templateDetails!.requiredFields.length} fields',
                  Colors.grey.shade700,
                ),
                if (widget.job.templateConfig!.autoExportEnabled) ...[
                  const SizedBox(height: 8),
                  _buildStatusRow(
                    'Auto Export',
                    'Enabled',
                    Colors.green,
                    icon: Icons.auto_mode,
                  ),
                ],
              ],

              // Template file info
              if (widget.job.templateConfig!.excelTemplatePath != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.job.templateConfig!.excelTemplatePath!.split('/').last,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This job uses Flutter forms for data entry. No Excel template is configured.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    String value,
    Color valueColor, {
    IconData? icon,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        if (icon != null) ...[
          Icon(
            icon,
            size: 14,
            color: valueColor,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact template indicator for use in lists
class CompactJobTemplateIndicator extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;

  const CompactJobTemplateIndicator({
    super.key,
    required this.job,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: job.hasExcelTemplate ? Colors.green.shade100 : Colors.blue.shade100,
          border: Border.all(
            color: job.hasExcelTemplate ? Colors.green.shade300 : Colors.blue.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          job.hasExcelTemplate ? Icons.file_present : Icons.phone_android,
          size: 14,
          color: job.hasExcelTemplate ? Colors.green.shade700 : Colors.blue.shade700,
        ),
      ),
    );
  }
}