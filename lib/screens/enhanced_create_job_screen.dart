import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/log_template.dart';
import '../model/job_model.dart';
import '../services/excel_template_selection_service.dart';
import '../widgets/excel_template_selector.dart';

class EnhancedCreateJobScreen extends StatefulWidget {
  const EnhancedCreateJobScreen({super.key});

  @override
  State<EnhancedCreateJobScreen> createState() => _EnhancedCreateJobScreenState();
}

class _EnhancedCreateJobScreenState extends State<EnhancedCreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExcelTemplateSelectionService _templateService = ExcelTemplateSelectionService();
  
  // Form controllers
  final _projectNumberController = TextEditingController();
  final _facilityNameController = TextEditingController();
  final _tankIdController = TextEditingController();
  final _createdByController = TextEditingController();
  
  // Template selection state
  LogType _selectedLogType = LogType.thermal;
  ExcelTemplateConfig? _selectedTemplate;
  JobTemplateSelection? _templateSelection;
  
  // UI state
  bool _isCreating = false;
  String? _errorMessage;
  bool _autoExportEnabled = false;

  @override
  void dispose() {
    _projectNumberController.dispose();
    _facilityNameController.dispose();
    _tankIdController.dispose();
    _createdByController.dispose();
    super.dispose();
  }

  void _onLogTypeChanged(LogType logType) {
    setState(() {
      _selectedLogType = logType;
      _selectedTemplate = null;
      _templateSelection = null;
    });
  }

  void _onTemplateSelected(ExcelTemplateConfig? template) {
    setState(() {
      _selectedTemplate = template;
      _templateSelection = null;
    });
    _updateTemplateSelection();
  }

  Future<void> _updateTemplateSelection() async {
    if (_selectedTemplate != null) {
      try {
        final selection = await _templateService.createJobTemplateSelection(
          logType: _selectedLogType,
          preferredExcelTemplate: _selectedTemplate,
        );
        setState(() {
          _templateSelection = selection;
          _errorMessage = null;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Template validation failed: $e';
          _templateSelection = null;
        });
      }
    }
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      // Create job template configuration
      JobTemplateConfig? templateConfig;
      if (_templateSelection != null) {
        templateConfig = JobTemplateConfig(
          logType: _selectedLogType,
          excelTemplateId: _selectedTemplate!.id,
          excelTemplatePath: _selectedTemplate!.excelTemplatePath,
          mappingFilePath: _selectedTemplate!.mappingFilePath,
          autoExportEnabled: _autoExportEnabled,
          configuredAt: DateTime.now(),
        );
      }

      // Create the job
      final job = Job(
        projectNumber: _projectNumberController.text.trim(),
        facilityName: _facilityNameController.text.trim(),
        tankId: _tankIdController.text.trim(),
        logType: _selectedLogType.id,
        templateConfig: templateConfig,
        createdAt: DateTime.now(),
        createdBy: _createdByController.text.trim(),
      );

      // TODO: Save job to your backend/database
      // await _jobService.createJob(job);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Job created successfully! ${job.hasExcelTemplate ? 'Excel template configured.' : 'Using Flutter forms only.'}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        Navigator.of(context).pop(job);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create job: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        title: Text(
          'Create New Job',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Job Information
              _buildSection(
                title: 'Job Information',
                icon: Icons.work_outline,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _projectNumberController,
                      label: 'Project Number',
                      hint: 'e.g., PRJ-2024-001',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Project number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _facilityNameController,
                      label: 'Facility Name',
                      hint: 'e.g., Houston Refinery',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Facility name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _tankIdController,
                      label: 'Tank/Unit ID',
                      hint: 'e.g., TANK-A-203',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Tank/Unit ID is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _createdByController,
                      label: 'Created By',
                      hint: 'e.g., John Smith',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Creator name is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Template Selection
              _buildSection(
                title: 'Template Configuration',
                icon: Icons.settings_outlined,
                child: Column(
                  children: [
                    ExcelTemplateSelector(
                      initialLogType: _selectedLogType,
                      initialTemplate: _selectedTemplate,
                      onLogTypeChanged: _onLogTypeChanged,
                      onTemplateSelected: _onTemplateSelected,
                    ),

                    // Auto-export option
                    if (_selectedTemplate != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF152042),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_mode,
                              color: Colors.blue.shade300,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Auto-Export Reports',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Automatically generate Excel reports when logs are completed',
                                    style: GoogleFonts.nunito(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _autoExportEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _autoExportEnabled = value;
                                });
                              },
                              activeColor: Colors.blue.shade400,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.shade700.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.nunito(
                            color: Colors.red.shade300,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isCreating
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Creating Job...',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Create Job',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.blue[400],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.grey[300],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(
              color: Colors.grey[500],
              fontSize: 16,
            ),
            filled: true,
            fillColor: const Color(0xFF0B132B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
          ),
        ),
      ],
    );
  }
}