import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/create_mock_job.dart';

class CreateDemoJobScreen extends StatefulWidget {
  const CreateDemoJobScreen({super.key});

  @override
  State<CreateDemoJobScreen> createState() => _CreateDemoJobScreenState();
}

class _CreateDemoJobScreenState extends State<CreateDemoJobScreen> {
  bool _isCreating = false;
  String _statusMessage = '';

  Future<void> _createDemoJob() async {
    setState(() {
      _isCreating = true;
      _statusMessage = 'Creating demo job...';
    });

    try {
      await MockJobCreator.createCompleteMockJob();
      
      if (mounted) {
        setState(() {
          _statusMessage = 'Demo job created successfully!';
          _isCreating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo job created! Check your project list.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back to project list after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error creating demo job: $e';
          _isCreating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          'Create Demo Job',
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF152042),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.science,
                      size: 64,
                      color: Colors.blue[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Demo Job Generator',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This will create a complete mock job with:',
                      style: GoogleFonts.nunito(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem('✅ Chevron Richmond Refinery project'),
                    _buildFeatureItem('📅 5 days of operational data (Aug 1-5, 2024)'),
                    _buildFeatureItem('⏰ 120 hourly log entries'),
                    _buildFeatureItem('📊 Complete system metrics'),
                    _buildFeatureItem('🎯 Final readings & certifications'),
                    _buildFeatureItem('🦺 Safety records'),
                    _buildFeatureItem('🔧 Calibration records'),
                    const SizedBox(height: 32),
                    if (_statusMessage.isNotEmpty) ...[
                      Text(
                        _statusMessage,
                        style: GoogleFonts.nunito(
                          color: _statusMessage.contains('Error') 
                              ? Colors.red[400] 
                              : Colors.green[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _createDemoJob,
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
                                    'Creating Demo Job...',
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Create Demo Job',
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
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[900]?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange[700]!.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This demo job uses realistic data patterns but is for demonstration purposes only.',
                        style: GoogleFonts.nunito(
                          color: Colors.orange[300],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}