import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ocr_result.dart';
import '../services/ocr_service.dart';

/// State provider for OCR results
final ocrResultProvider = StateProvider<OcrResult?>((ref) => null);
final ocrLoadingProvider = StateProvider<bool>((ref) => false);

/// OCR Scan Screen for capturing and processing field logs
class OcrScanScreen extends ConsumerStatefulWidget {
  /// Optional callback to handle OCR results
  final Function(Map<String, dynamic>)? onDataExtracted;

  /// Title for the screen
  final String title;

  /// Instructions for the operator
  final String instructions;

  const OcrScanScreen({
    super.key,
    this.onDataExtracted,
    this.title = 'Scan Field Log',
    this.instructions =
        'Take a photo of your paper log or control panel to extract data automatically.',
  });

  @override
  ConsumerState<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends ConsumerState<OcrScanScreen> {
  final _ocrService = OcrService();
  File? _capturedImage;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  /// Take photo using camera
  Future<void> _takePhoto() async {
    try {
      ref.read(ocrLoadingProvider.notifier).state = true;

      final imageFile = await _ocrService.takePhoto();
      if (imageFile != null) {
        setState(() {
          _capturedImage = imageFile;
        });
        await _processImage(imageFile);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: ${e.toString()}');
    } finally {
      ref.read(ocrLoadingProvider.notifier).state = false;
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      ref.read(ocrLoadingProvider.notifier).state = true;

      final imageFile = await _ocrService.pickFromGallery();
      if (imageFile != null) {
        setState(() {
          _capturedImage = imageFile;
        });
        await _processImage(imageFile);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    } finally {
      ref.read(ocrLoadingProvider.notifier).state = false;
    }
  }

  /// Process image with OCR
  Future<void> _processImage(File imageFile) async {
    try {
      ref.read(ocrLoadingProvider.notifier).state = true;

      debugPrint('🔍 Processing image for OCR...');
      final result = await _ocrService.processImageWithPreprocessing(imageFile);

      // Update state with result
      ref.read(ocrResultProvider.notifier).state = result;

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
      _showErrorSnackBar('OCR processing failed: ${e.toString()}');
    } finally {
      ref.read(ocrLoadingProvider.notifier).state = false;
    }
  }

  /// Use extracted data
  void _useExtractedData() {
    final ocrResult = ref.read(ocrResultProvider);
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
    ref.read(ocrResultProvider.notifier).state = null;
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('❌ $message')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(ocrLoadingProvider);
    final ocrResult = ref.watch(ocrResultProvider);

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
            // Instructions Card
            _buildInstructionsCard(),
            const SizedBox(height: 24),

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
              Expanded(
                child: Text(
                  'OCR Scanner',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/enhanced-ocr-scan', extra: {
                    'title': 'Enhanced OCR Scan',
                    'instructions':
                        'Take a photo of your thermal log to extract data with anti-hallucination protection.',
                    'onDataExtracted': widget.onDataExtracted,
                  });
                },
                icon: const Icon(Icons.shield, size: 16),
                label: const Text('Enhanced'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
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

  Widget _buildCameraControls() {
    return Column(
      children: [
        // Take Photo Button
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt, size: 28),
            label: Text(
              'Take Photo',
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
        child: Image.file(
          _capturedImage!,
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
            'Extracting text and data fields',
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
                  Icon(Icons.warning_amber,
                      color: Colors.orange[300], size: 20),
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
                  result.rawText.isNotEmpty
                      ? result.rawText
                      : 'No text detected',
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
