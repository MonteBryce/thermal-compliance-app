import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ocr_result.dart';
import '../services/enhanced_ocr_service.dart';

/// State providers for OCR
final webOcrResultProvider = StateProvider<OcrResult?>((ref) => null);
final webOcrLoadingProvider = StateProvider<bool>((ref) => false);
final webOcrErrorProvider = StateProvider<String?>((ref) => null);

/// Web-compatible OCR Scan Screen
class WebOcrScanScreen extends ConsumerStatefulWidget {
  /// Optional callback to handle OCR results
  final Function(Map<String, dynamic>)? onDataExtracted;
  
  /// Title for the screen
  final String title;
  
  /// Instructions for the operator
  final String instructions;

  const WebOcrScanScreen({
    super.key,
    this.onDataExtracted,
    this.title = 'Scan Field Log',
    this.instructions = 'Take a photo or upload an image to extract data automatically.',
  });

  @override
  ConsumerState<WebOcrScanScreen> createState() => _WebOcrScanScreenState();
}

class _WebOcrScanScreenState extends ConsumerState<WebOcrScanScreen> {
  final _ocrService = EnhancedOcrService();
  XFile? _capturedImage;
  
  @override
  void dispose() {
    // Clear providers on dispose
    ref.read(webOcrResultProvider.notifier).state = null;
    ref.read(webOcrLoadingProvider.notifier).state = false;
    ref.read(webOcrErrorProvider.notifier).state = null;
    super.dispose();
  }

  /// Take photo using camera
  Future<void> _takePhoto() async {
    try {
      _setLoading(true);
      _clearError();
      
      final imageFile = await _ocrService.takePhoto();
      if (imageFile != null) {
        setState(() {
          _capturedImage = imageFile;
        });
        await _processImage(imageFile);
      }
    } catch (e) {
      _setError('Failed to take photo: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      _setLoading(true);
      _clearError();
      
      final imageFile = await _ocrService.pickFromGallery();
      if (imageFile != null) {
        setState(() {
          _capturedImage = imageFile;
        });
        await _processImage(imageFile);
      }
    } catch (e) {
      _setError('Failed to pick image: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Process image with OCR
  Future<void> _processImage(XFile imageFile) async {
    try {
      _setLoading(true);
      _clearError();
      
      debugPrint('🔍 Processing image for OCR...');
      final result = await _ocrService.processImage(imageFile);
      
      // Update state with result
      ref.read(webOcrResultProvider.notifier).state = result;
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('✅ Found ${result.extractedFields.length} data fields'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ OCR processing failed: $e');
      _setError('OCR processing failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Use extracted data
  void _useExtractedData() {
    final ocrResult = ref.read(webOcrResultProvider);
    if (ocrResult == null) return;

    // Convert OCR result to thermal reading data
    final extractedData = _ocrService.mapToThermalReading(ocrResult);
    
    debugPrint('📊 Extracted data: $extractedData');
    
    // Call the callback if provided
    if (widget.onDataExtracted != null) {
      widget.onDataExtracted!(extractedData);
    }
    
    // Return to previous screen with the data
    context.pop(extractedData);
  }

  /// Clear current results and image
  void _clearResults() {
    setState(() {
      _capturedImage = null;
    });
    ref.read(webOcrResultProvider.notifier).state = null;
    _clearError();
  }

  /// Helper methods for state management
  void _setLoading(bool loading) {
    ref.read(webOcrLoadingProvider.notifier).state = loading;
  }

  void _setError(String error) {
    ref.read(webOcrErrorProvider.notifier).state = error;
  }

  void _clearError() {
    ref.read(webOcrErrorProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(webOcrLoadingProvider);
    final ocrResult = ref.watch(webOcrResultProvider);
    final error = ref.watch(webOcrErrorProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0B132B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (ocrResult != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearResults,
              tooltip: 'Clear results',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform info
            _buildPlatformInfo(),
            const SizedBox(height: 16),
            
            // Instructions Card
            _buildInstructionsCard(),
            const SizedBox(height: 24),
            
            // Error Display
            if (error != null) ...[ 
              _buildErrorCard(error),
              const SizedBox(height: 16),
            ],
            
            // Camera Controls
            if (_capturedImage == null) ...[ 
              _buildCameraControls(),
            ] else ...[ 
              _buildImagePreview(),
              const SizedBox(height: 24),
            ],
            
            // Loading Indicator
            if (isLoading) ...[ 
              _buildLoadingIndicator(),
              const SizedBox(height: 24),
            ],
            
            // OCR Results
            if (ocrResult != null) ...[ 
              _buildOcrResults(ocrResult),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformInfo() {
    String platformInfo;
    String ocrEngine;
    Color statusColor;

    if (kIsWeb) {
      platformInfo = 'Web Platform';
      ocrEngine = 'Tesseract.js (Free)';
      statusColor = Colors.blue;
    } else if (Platform.isAndroid || Platform.isIOS) {
      platformInfo = 'Mobile Platform';
      ocrEngine = 'Google Vision API (Requires API Key)';
      statusColor = Colors.green;
    } else {
      platformInfo = 'Desktop Platform';
      ocrEngine = 'Limited OCR Support';
      statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platformInfo,
                  style: GoogleFonts.nunito(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'OCR Engine: $ocrEngine',
                  style: GoogleFonts.nunito(
                    color: statusColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: Colors.blue[400],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'OCR Scanner',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.instructions,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildTipsList(),
        ],
      ),
    );
  }

  Widget _buildTipsList() {
    final tips = [
      'Ensure good lighting for best results',
      'Hold camera steady and focus on text',
      'Capture control panel displays clearly',
      'Include units (°F, PPM, CFM, etc.) when possible',
      if (kIsWeb) 'Web OCR may take 10-30 seconds to process',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips for better results:',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.blue[300],
          ),
        ),
        const SizedBox(height: 8),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              Expanded(
                child: Text(
                  tip,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OCR Error',
                  style: GoogleFonts.nunito(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: GoogleFonts.nunito(
                    color: Colors.red[300],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearError,
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Column(
      children: [
        // Take Photo Button (only show on mobile platforms)
        if (!kIsWeb || true) ...[  // Allow camera on web too
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt, size: 28),
              label: Text(
                kIsWeb ? 'Take Photo (Web)' : 'Take Photo',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Pick from Gallery Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library, size: 24),
            label: Text(
              'Choose from Gallery',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[400],
              side: BorderSide(color: Colors.blue[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_capturedImage == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: kIsWeb 
          ? Image.network(
              _capturedImage!.path,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 48),
                  ),
                );
              },
            )
          : Image.file(
              File(_capturedImage!.path),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            'Processing image...',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            kIsWeb 
              ? 'Web OCR may take 10-30 seconds'
              : 'Extracting text and data fields',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrResults(OcrResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.text_fields,
                color: Colors.green[400],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Extracted Data',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(result.confidence * 100).toInt()}% confidence',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.green[300],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Extracted Fields
          if (result.extractedFields.isNotEmpty) ...[ 
            Text(
              'Found ${result.extractedFields.length} data fields:',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.grey[300],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...result.extractedFields.map((field) => _buildFieldRow(field)),
          ] else ...[ 
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[300], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No structured data found. Try a clearer image with visible numbers and units.',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.orange[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Raw Text (Collapsible)
          const SizedBox(height: 20),
          ExpansionTile(
            title: Text(
              'Raw Text',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.grey[300],
                fontWeight: FontWeight.w600,
              ),
            ),
            iconColor: Colors.grey[400],
            collapsedIconColor: Colors.grey[400],
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.rawText.isNotEmpty ? result.rawText : 'No text detected',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(ExtractedField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Field Icon
          Icon(
            _getFieldIcon(field.type),
            color: Colors.blue[300],
            size: 20,
          ),
          const SizedBox(width: 12),
          
          // Field Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.fieldName,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      field.value,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.green[300],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (field.unit.isNotEmpty) ...[ 
                      const SizedBox(width: 4),
                      Text(
                        field.unit,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Confidence Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getConfidenceColor(field.confidence).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${(field.confidence * 100).toInt()}%',
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: _getConfidenceColor(field.confidence),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Use Data Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _useExtractedData,
            icon: const Icon(Icons.check_circle, size: 24),
            label: Text(
              'Use This Data',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Scan Again Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _clearResults,
            icon: const Icon(Icons.refresh, size: 20),
            label: Text(
              'Scan Again',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[400],
              side: BorderSide(color: Colors.blue[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getFieldIcon(FieldType type) {
    switch (type) {
      case FieldType.temperature:
        return Icons.thermostat;
      case FieldType.pressure:
        return Icons.speed;
      case FieldType.flowRate:
        return Icons.air;
      case FieldType.ppm:
        return Icons.science;
      case FieldType.hour:
      case FieldType.time:
        return Icons.access_time;
      case FieldType.text:
      default:
        return Icons.text_fields;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}