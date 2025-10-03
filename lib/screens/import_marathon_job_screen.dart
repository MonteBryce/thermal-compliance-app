import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/marathon_job_importer.dart';

class ImportMarathonJobScreen extends StatefulWidget {
  const ImportMarathonJobScreen({super.key});

  @override
  State<ImportMarathonJobScreen> createState() => _ImportMarathonJobScreenState();
}

class _ImportMarathonJobScreenState extends State<ImportMarathonJobScreen> {
  bool _isImporting = false;
  String _statusMessage = '';

  Future<void> _importMarathonJob() async {
    setState(() {
      _isImporting = true;
      _statusMessage = 'Importing Marathon GBR real data...';
    });

    try {
      await MarathonJobImporter.importMarathonJob();
      
      if (mounted) {
        setState(() {
          _statusMessage = 'Marathon job imported successfully!';
          _isImporting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marathon job imported! Check project 2025-2-095.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        
        // Navigate back to project list after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error importing Marathon job: $e';
          _isImporting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
          'Import Marathon Job',
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
                    // Marathon logo placeholder
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.local_gas_station,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Marathon GBR Real Data',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Project: 2025-2-095 • Tank 223',
                      style: GoogleFonts.nunito(
                        color: Colors.blue[300],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Job details
                    _buildJobDetail('Work Order', 'M25-021-MTT/10100'),
                    _buildJobDetail('Location', 'Texas City, TX'),
                    _buildJobDetail('Dates', 'July 15-17, 2025'),
                    _buildJobDetail('Product', 'Sour Water'),
                    _buildJobDetail('Target', '10% LEL'),
                    _buildJobDetail('Temp', '>1250°F'),
                    
                    const SizedBox(height: 24),
                    Text(
                      'This will import REAL hourly data:',
                      style: GoogleFonts.nunito(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem('📊 48 hours of actual readings'),
                    _buildFeatureItem('🔥 Real VOC inlet/outlet PPM values'),
                    _buildFeatureItem('💨 Actual vapor flow rates'),
                    _buildFeatureItem('🌡️ Real chamber temperatures'),
                    _buildFeatureItem('⚠️ H2S and benzene measurements'),
                    _buildFeatureItem('📈 LEL percentage tracking'),
                    
                    const SizedBox(height: 32),
                    if (_statusMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _statusMessage.contains('Error') 
                              ? Colors.red[900]?.withOpacity(0.3)
                              : Colors.green[900]?.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _statusMessage.contains('Error') 
                                ? Colors.red[700]! 
                                : Colors.green[700]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
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
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isImporting ? null : _importMarathonJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isImporting
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
                                    'Importing Real Data...',
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Import Marathon Job',
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
                  color: Colors.blue[900]?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue[700]!.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.blue[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This contains REAL operational data from Marathon GBR for authentic demonstration purposes.',
                        style: GoogleFonts.nunito(
                          color: Colors.blue[300],
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

  Widget _buildJobDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.nunito(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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