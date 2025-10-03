import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/enhanced_ocr_service.dart';
import '../providers/enhanced_ocr_providers.dart';
import '../widgets/ocr_validation_widget.dart';
import '../models/ocr_result.dart';

/// Enhanced OCR Scan Screen with anti-hallucination capabilities
class EnhancedOcrScanScreen extends ConsumerStatefulWidget {
  /// Optional callback to handle OCR results
  final Function(Map<String, dynamic>)? onDataExtracted;

  /// Title for the screen
  final String title;

  /// Instructions for the operator
  final String instructions;

  /// Target hour for parsing
  final String? targetHour;

  const EnhancedOcrScanScreen({
    super.key,
    this.onDataExtracted,
    this.title = 'Enhanced OCR Scan',
    this.instructions =
        'Take a photo of your thermal log to extract data with anti-hallucination protection.',
    this.targetHour,
  });

  @override
  ConsumerState<EnhancedOcrScanScreen> createState() =>
      _EnhancedOcrScanScreenState();
}

class _EnhancedOcrScanScreenState extends ConsumerState<EnhancedOcrScanScreen> {
  final _enhancedOcrService = EnhancedOcrService();
  File? _capturedImage;

  @override
  void dispose() {
    _enhancedOcrService.dispose();
    super.dispose();
  }

  /// Take photo using camera
  Future<void> _takePhoto() async {
    try {
      ref.read(enhancedOcrLoadingProvider.notifier).state = true;
      ref
          .read(enhancedOcrProcessingStateProvider.notifier)
          .startProcessing('Taking photo...');

      final imageFile = await _enhancedOcrService.takePhoto();
      if (imageFile != null) {
        setState(() {
          _capturedImage = imageFile;
        });
        await _processImage(imageFile);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: ${e.toString()}');
      ref
          .read(enhancedOcrProcessingStateProvider.notifier)
          .setError(e.toString());
    } finally {
      ref.read(enhancedOcrLoadingProvider.notifier).state = false;
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      ref.read(enhancedOcrLoadingProvider.notifier).state = true;
      ref
          .read(enhancedOcrProcessingStateProvider.notifier)
          .startProcessing('Loading image...');

      final imageFile = await _enhancedOcrService.pickFromGallery();
      if (imageFile != null) {
        setState(() {
          _capturedImage = imageFile;
        });
        await _processImage(imageFile);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
      ref
          .read(enhancedOcrProcessingStateProvider.notifier)
          .setError(e.toString());
    } finally {
      ref.read(enhancedOcrLoadingProvider.notifier).state = false;
    }
  }

  /// Process image with enhanced OCR
  Future<void> _processImage(File imageFile) async {
    try {
      ref.read(enhancedOcrLoadingProvider.notifier).state = true;
      ref
          .read(enhancedOcrProcessingStateProvider.notifier)
          .startProcessing('Extracting text...');

      debugPrint('🔍 Processing image with enhanced OCR...');

      // Get settings from providers
      final settings = ref.read(ocrSettingsProvider);

      final result =
          await _enhancedOcrService.processImageWithAntiHallucination(
        imageFile,
        targetHour: widget.targetHour,
        strictMode: settings.strictMode,
        enableDebugMode: settings.debugMode,
      );

      // Update state with result
      ref.read(enhancedOcrResultProvider.notifier).state = result;

      // Update processing stats
      final stats = _enhancedOcrService.getProcessingStats(result);
      ref.read(ocrProcessingStatsProvider.notifier).state = stats;

      // Update validation state
      ref.read(ocrValidationProvider.notifier).state = {
        'isValid': result.validationResult.isValid,
        'requiresManualReview': result.validationResult.requiresManualReview,
        'confidence': result.confidence,
        'errors': result.validationResult.errors,
        'warnings': result.validationResult.warnings,
      };

      // Update hallucination flags
      ref.read(hallucinationFlagsProvider.notifier).state = result
          .antiHallucinationResult.hallucinationFlags
          .map((f) => f.toJson())
          .toList();

      // Update manual review state
      ref.read(manualReviewRequiredProvider.notifier).state =
          result.validationResult.requiresManualReview;

      // Complete processing
      ref.read(enhancedOcrProcessingStateProvider.notifier).completeProcessing(
            debugInfo: result.debugInfo,
          );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                    '✅ Enhanced OCR completed with ${result.extractedFields.length} validated fields'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Enhanced OCR processing failed: $e');
      _showErrorSnackBar('Enhanced OCR processing failed: ${e.toString()}');
      ref
          .read(enhancedOcrProcessingStateProvider.notifier)
          .setError(e.toString());
    } finally {
      ref.read(enhancedOcrLoadingProvider.notifier).state = false;
    }
  }

  /// Use extracted data
  void _useExtractedData() {
    final ocrResult = ref.read(enhancedOcrResultProvider);
    if (ocrResult == null) return;

    // Convert OCR result to thermal reading data
    final extractedData = _enhancedOcrService.mapToThermalReading(ocrResult);

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
    ref.read(enhancedOcrResultProvider.notifier).state = null;
    ref.read(ocrProcessingStatsProvider.notifier).state = null;
    ref.read(ocrValidationProvider.notifier).state = null;
    ref.read(hallucinationFlagsProvider.notifier).state = [];
    ref.read(manualReviewRequiredProvider.notifier).state = false;
    ref.read(enhancedOcrProcessingStateProvider.notifier).reset();
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

  /// Show settings dialog
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildSettingsDialog(),
    );
  }

  Widget _buildSettingsDialog() {
    final settings = ref.watch(ocrSettingsProvider);

    return AlertDialog(
      title: Text('OCR Settings',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Debug Mode'),
            subtitle: const Text('Show detailed processing information'),
            value: settings.debugMode,
            onChanged: (value) {
              ref.read(ocrSettingsProvider.notifier).toggleDebugMode();
            },
          ),
          SwitchListTile(
            title: const Text('Strict Mode'),
            subtitle: const Text('Apply stricter validation rules'),
            value: settings.strictMode,
            onChanged: (value) {
              ref.read(ocrSettingsProvider.notifier).toggleStrictMode();
            },
          ),
          SwitchListTile(
            title: const Text('Anti-Hallucination'),
            subtitle: const Text('Enable hallucination detection'),
            value: settings.enableAntiHallucination,
            onChanged: (value) {
              ref.read(ocrSettingsProvider.notifier).toggleAntiHallucination();
            },
          ),
          SwitchListTile(
            title: const Text('Validation'),
            subtitle: const Text('Enable multi-layer validation'),
            value: settings.enableValidation,
            onChanged: (value) {
              ref.read(ocrSettingsProvider.notifier).toggleValidation();
            },
          ),
          SwitchListTile(
            title: const Text('Manual Review'),
            subtitle: const Text('Require manual review for low confidence'),
            value: settings.requireManualReview,
            onChanged: (value) {
              ref.read(ocrSettingsProvider.notifier).toggleManualReview();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(enhancedOcrLoadingProvider);
    final ocrResult = ref.watch(enhancedOcrResultProvider);
    final processingState = ref.watch(enhancedOcrProcessingStateProvider);

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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: 'OCR Settings',
          ),
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
            _buildCameraControls(),
            const SizedBox(height: 24),

            // Processing State
            if (processingState.isProcessing)
              _buildProcessingState(processingState),

            // Results
            if (ocrResult != null) ...[
              _buildResultsSection(ocrResult),
              const SizedBox(height: 16),

              // Validation Widget
              OcrValidationWidget(
                ocrResult: ocrResult,
                onManualReview: () {
                  // TODO: Implement manual review screen
                  _showManualReviewDialog(ocrResult);
                },
                onAccept: _useExtractedData,
                onReject: _clearResults,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      color: const Color(0xFF1E3A8A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[200]),
                const SizedBox(width: 8),
                Text(
                  'Enhanced OCR Instructions',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.instructions,
              style: GoogleFonts.nunito(
                color: Colors.blue[100],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This enhanced system includes anti-hallucination protection to prevent false data generation.',
              style: GoogleFonts.nunito(
                color: Colors.blue[200],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraControls() {
    final isLoading = ref.watch(enhancedOcrLoadingProvider);

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _pickFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingState(EnhancedOcrProcessingState processingState) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    processingState.currentStep ?? 'Processing...',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (processingState.progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: processingState.progress),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(EnhancedOcrResult ocrResult) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Extracted Fields',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (ocrResult.extractedFields.isEmpty)
              Text(
                'No fields extracted - possible hallucination detected',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...ocrResult.extractedFields
                  .map((field) => _buildFieldItem(field)),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldItem(ExtractedField field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              field.fieldName,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              field.value,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
          if (field.unit.isNotEmpty)
            Text(
              field.unit,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(width: 8),
          Text(
            '${(field.confidence * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: _getConfidenceColor(field.confidence),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showManualReviewDialog(EnhancedOcrResult ocrResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manual Review Required',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The OCR system detected potential issues that require manual review:',
              style: GoogleFonts.nunito(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (ocrResult.validationResult.errors.isNotEmpty) ...[
              Text(
                'Errors:',
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
              ...ocrResult.validationResult.errors.map((error) => Text(
                  '• $error',
                  style: GoogleFonts.nunito(fontSize: 12, color: Colors.red))),
              const SizedBox(height: 8),
            ],
            if (ocrResult.validationResult.warnings.isNotEmpty) ...[
              Text(
                'Warnings:',
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange),
              ),
              ...ocrResult.validationResult.warnings.map((warning) => Text(
                  '• $warning',
                  style:
                      GoogleFonts.nunito(fontSize: 12, color: Colors.orange))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _useExtractedData();
            },
            child: const Text('Accept Anyway'),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
