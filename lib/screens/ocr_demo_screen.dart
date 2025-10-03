import 'package:flutter/material.dart';
import '../services/ocr_engine_service.dart';
import '../services/ocr_config_helper.dart';
import '../widgets/ocr_capture_widget.dart';
import '../models/ocr_result.dart';

/// Demo screen showcasing the complete OCR flow
class OcrDemoScreen extends StatefulWidget {
  const OcrDemoScreen({super.key});

  @override
  State<OcrDemoScreen> createState() => _OcrDemoScreenState();
}

class _OcrDemoScreenState extends State<OcrDemoScreen> {
  OcrResult? _lastOcrResult;
  String? _lastError;
  bool _showAdvancedOptions = false;
  OcrEngine _selectedEngine = OcrEngine.tesseract; // Default to Tesseract
  Rect? _cropRect;

  @override
  void initState() {
    super.initState();
    // Initialize with Tesseract configuration for thermal logs
    OcrConfigHelper.setupForThermalLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handwriting OCR Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () =>
                setState(() => _showAdvancedOptions = !_showAdvancedOptions),
            icon: const Icon(Icons.settings),
            tooltip: 'Advanced Options',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.camera_alt, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Handwriting OCR',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture paper logs and extract handwritten data using HandwritingOCR.com',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Advanced options
            if (_showAdvancedOptions) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Advanced Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // OCR Engine selection
                      const Text('OCR Engine:'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<OcrEngine>(
                        value: _selectedEngine,
                        decoration: const InputDecoration(
                          labelText: 'Select OCR Engine',
                          border: OutlineInputBorder(),
                        ),
                        items: OcrEngine.values.map((engine) {
                          return DropdownMenuItem(
                            value: engine,
                            child: Text(engine.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedEngine = value);
                            // Update the OCR service configuration using helper
                            switch (value) {
                              case OcrEngine.tesseract:
                                OcrConfigHelper.setupForThermalLogs();
                                break;
                              case OcrEngine.api:
                                OcrConfigHelper.setupForApiFallback();
                                break;
                              case OcrEngine.mlKit:
                                OcrConfigHelper.setupOcrService(
                                  OcrConfigHelper.getMlKitConfig(),
                                );
                                break;
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Crop selection
                      const Text('Image Crop (Optional):'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _cropRect == null ? 'none' : 'custom',
                              decoration: const InputDecoration(
                                labelText: 'Crop Mode',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'none',
                                  child: Text('No Crop'),
                                ),
                                DropdownMenuItem(
                                  value: 'custom',
                                  child: Text('Custom Crop'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  if (value == 'none') {
                                    _cropRect = null;
                                  } else {
                                    // Example crop rect (you can make this interactive)
                                    _cropRect =
                                        const Rect.fromLTWH(100, 100, 300, 400);
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      if (_cropRect != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Crop: ${_cropRect!.left.round()}, ${_cropRect!.top.round()} - '
                          '${_cropRect!.width.round()}x${_cropRect!.height.round()}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // OCR Capture Widget
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OcrCaptureWidget(
                  onOcrComplete: _handleOcrComplete,
                  onError: _handleOcrError,
                ),
              ),
            ),

            // Error display
            if (_lastError != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _lastError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => setState(() => _lastError = null),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // OCR Results
            if (_lastOcrResult != null) ...[
              const SizedBox(height: 16),
              OcrResultDisplay(
                ocrResult: _lastOcrResult!,
                onRetry: () => _retryOcr(),
              ),
            ],

            // Instructions
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Tap "Capture with Camera" to take a photo of your paper log\n'
                      '2. Or tap "Pick from Gallery" to select an existing image\n'
                      '3. The image will be automatically preprocessed for better OCR\n'
                      '4. The processed image is sent to HandwritingOCR.com for text extraction\n'
                      '5. Results are displayed below with extracted field data',
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick test button for Tesseract
                    if (_selectedEngine == OcrEngine.tesseract) ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          setState(() {
                            _lastError = null;
                          });

                          try {
                            // Simulate Tesseract OCR processing
                            await Future.delayed(const Duration(seconds: 2));

                            const testResult = '''
 Temperature: 185.5°F
 Pressure: 2.4 PSI
 Flow Rate: 12.8 GPM
 Time: 14:30
 Date: 2024-01-15
 Operator: John Smith
 Notes: System running normally
 Equipment: Pump Station A
 Status: Operational
 ''';

                            final ocrResult = testResult.toOcrResult();
                            _handleOcrComplete(ocrResult);
                          } catch (e) {
                            _handleOcrError(e.toString());
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Quick Test (Tesseract)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        _selectedEngine == OcrEngine.tesseract
                            ? '💡 Tesseract OCR: Local processing with character whitelist for better accuracy. '
                                'The preprocessing will enhance contrast and resize the image for optimal OCR performance.'
                            : _selectedEngine == OcrEngine.api
                                ? '💡 API OCR: Cloud-based processing with HandwritingOCR.com. '
                                    'The preprocessing will enhance contrast and resize the image for optimal OCR performance.'
                                : '💡 ML Kit OCR: Google\'s on-device OCR. '
                                    'The preprocessing will enhance contrast and resize the image for optimal OCR performance.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle successful OCR completion
  void _handleOcrComplete(OcrResult ocrResult) {
    setState(() {
      _lastOcrResult = ocrResult;
      _lastError = null;
    });

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'OCR completed! Found ${ocrResult.extractedFields.length} fields',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Handle OCR errors
  void _handleOcrError(String error) {
    setState(() {
      _lastError = error;
    });

    // Show error snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OCR failed: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _retryOcr,
        ),
      ),
    );
  }

  /// Retry OCR with last settings
  void _retryOcr() {
    // This would require storing the last image or settings
    // For now, just clear the error
    setState(() {
      _lastError = null;
    });
  }
}
