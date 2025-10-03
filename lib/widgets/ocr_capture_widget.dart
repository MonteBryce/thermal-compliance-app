import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_engine_service.dart';
import '../models/ocr_result.dart';

/// Widget for capturing images and performing OCR using the selected engine
class OcrCaptureWidget extends StatefulWidget {
  final Function(OcrResult) onOcrComplete;
  final Function(String) onError;

  const OcrCaptureWidget({
    super.key,
    required this.onOcrComplete,
    required this.onError,
  });

  @override
  State<OcrCaptureWidget> createState() => _OcrCaptureWidgetState();
}

class _OcrCaptureWidgetState extends State<OcrCaptureWidget> {
  final OcrEngineService _ocrService = OcrEngineService();
  bool _isProcessing = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status display
        if (_statusMessage.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _isProcessing
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isProcessing ? Colors.blue : Colors.green,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isProcessing ? Icons.hourglass_empty : Icons.check_circle,
                  color: _isProcessing ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _isProcessing ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Camera capture button
        ElevatedButton.icon(
          onPressed: _isProcessing
              ? null
              : () => _captureAndProcess(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Capture with Camera'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Gallery pick button
        ElevatedButton.icon(
          onPressed: _isProcessing
              ? null
              : () => _captureAndProcess(ImageSource.gallery),
          icon: const Icon(Icons.photo_library),
          label: const Text('Pick from Gallery'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Processing indicator
        if (_isProcessing) ...[
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          const Text(
            'Processing image...',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  /// Capture image and process with OCR
  Future<void> _captureAndProcess(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturing image...';
    });

    try {
      // Process image with OCR
      final String ocrText = await _ocrService.processImageWithOcr(
        source: source,
        enablePreprocessing: true,
      );

      setState(() {
        _statusMessage = 'OCR completed successfully!';
      });

      // Convert to OcrResult and notify parent
      final OcrResult ocrResult = ocrText.toOcrResult();
      widget.onOcrComplete(ocrResult);
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
      widget.onError(e.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}

/// Widget to display OCR results
class OcrResultDisplay extends StatelessWidget {
  final OcrResult ocrResult;
  final VoidCallback? onRetry;

  const OcrResultDisplay({
    super.key,
    required this.ocrResult,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.text_fields, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'OCR Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onRetry != null)
                  IconButton(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Retry OCR',
                  ),
              ],
            ),

            const Divider(),

            // Confidence score
            Row(
              children: [
                const Text('Confidence: '),
                Text(
                  '${(ocrResult.confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ocrResult.confidence > 0.7
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Raw text
            const Text(
              'Raw OCR Text:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Text(
                ocrResult.rawText.isEmpty
                    ? 'No text detected'
                    : ocrResult.rawText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),

            // Extracted fields
            if (ocrResult.extractedFields.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Extracted Fields:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...ocrResult.extractedFields.map((field) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '${field.fieldName}: ',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text('${field.value} ${field.unit}'),
                        const Spacer(),
                        Text(
                          '(${(field.confidence * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            // Timestamp
            const SizedBox(height: 12),
            Text(
              'Scanned: ${ocrResult.scanTimestamp.toString().substring(0, 19)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
