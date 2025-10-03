import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:js/js.dart';
import 'package:universal_html/html.dart' as html;
import '../models/ocr_result.dart' as ocr_result;
import '../models/hourly_reading_models.dart';
import 'intelligent_ocr_parser.dart';

// JavaScript interop for Tesseract.js
@JS('TesseractWorker')
external TesseractWorker createTesseractWorker();

@JS()
@anonymous
class TesseractWorker {
  external void recognize(dynamic image, String language);
  external void terminate();
}

@JS()
@anonymous
class TesseractResult {
  external TesseractData get data;
}

@JS()
@anonymous
class TesseractData {
  external String get text;
  external double get confidence;
}

/// Web-compatible OCR service supporting multiple engines
class WebOcrService {
  static final _instance = WebOcrService._internal();
  factory WebOcrService() => _instance;
  WebOcrService._internal();

  final _imagePicker = ImagePicker();

  // Configuration
  static const String _googleVisionApiKey = 'YOUR_GOOGLE_VISION_API_KEY';
  static const String _azureEndpoint = 'YOUR_AZURE_ENDPOINT';
  static const String _azureApiKey = 'YOUR_AZURE_API_KEY';

  /// Check camera permissions (only on mobile platforms)
  Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true; // Web handles permissions via browser

    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Take photo from camera (platform-safe)
  Future<XFile?> takePhoto() async {
    try {
      if (!kIsWeb) {
        final hasPermission = await requestCameraPermission();
        if (!hasPermission) {
          throw Exception('Camera permission denied');
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return image;
    } catch (e) {
      debugPrint('❌ Error taking photo: $e');
      rethrow;
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return image;
    } catch (e) {
      debugPrint('❌ Error picking from gallery: $e');
      rethrow;
    }
  }

  /// Main OCR processing method - automatically selects best available engine
  Future<ocr_result.OcrResult> processImage(XFile imageFile) async {
    try {
      debugPrint('🔍 Starting OCR processing...');

      // Try engines in order of preference
      if (_googleVisionApiKey != 'YOUR_GOOGLE_VISION_API_KEY') {
        return await _processWithGoogleVision(imageFile);
      } else if (kIsWeb) {
        return await _processWithTesseractJS(imageFile);
      } else {
        throw Exception('No OCR engine available for this platform');
      }
    } catch (e) {
      debugPrint('❌ OCR processing failed: $e');
      throw Exception('Failed to process image: $e');
    }
  }

  /// Google Vision API OCR (most accurate, requires API key)
  Future<ocr_result.OcrResult> _processWithGoogleVision(XFile imageFile) async {
    try {
      debugPrint('🔍 Using Google Vision API...');

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(
            'https://vision.googleapis.com/v1/images:annotate?key=$_googleVisionApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'TEXT_DETECTION', 'maxResults': 1}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final annotations = data['responses'][0]['textAnnotations'] as List?;

        if (annotations != null && annotations.isNotEmpty) {
          final text = annotations[0]['description'] as String;
          final extractedFields =
              ocr_result.FieldDataPatterns.extractFields(text);

          return ocr_result.OcrResult(
            rawText: text,
            scanTimestamp: DateTime.now(),
            extractedFields: extractedFields,
            confidence: 0.9, // Google Vision is typically high confidence
          );
        }
      }

      throw Exception('Google Vision API failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Google Vision error: $e');
      rethrow;
    }
  }

  /// Tesseract.js OCR (free, web-only)
  Future<ocr_result.OcrResult> _processWithTesseractJS(XFile imageFile) async {
    try {
      debugPrint('🔍 Using Tesseract.js...');

      if (!kIsWeb) {
        throw Exception('Tesseract.js only works on web platform');
      }

      final bytes = await imageFile.readAsBytes();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Get the table-structured text
      final mockText = await _simulateTesseractProcessing(bytes);

      // Use our intelligent table parser to extract structured data
      final intelligentParser = IntelligentOcrParser();
      const targetHour =
          '0000'; // Default to first hour, can be made configurable

      debugPrint(
          '🧠 Using intelligent table parser for structured extraction...');
      final hourlyReading =
          await intelligentParser.parseIntelligently(mockText, targetHour);

      // Convert HourlyReading back to OcrResult format for compatibility
      final extractedFields = hourlyReading.fieldMatches
          .map((field) => ocr_result.ExtractedField(
                fieldName: field.name,
                value: field.value.toString(),
                confidence: field.confidence,
                type: _mapFieldType(field.type),
                unit: field.unit ?? '',
              ))
          .toList();

      return ocr_result.OcrResult(
        rawText: mockText,
        scanTimestamp: DateTime.now(),
        extractedFields: extractedFields,
        confidence: hourlyReading.overallConfidence,
      );
    } catch (e) {
      debugPrint('❌ Tesseract.js error: $e');
      rethrow;
    }
  }

  /// Microsoft Cognitive Services OCR (alternative paid option)
  Future<ocr_result.OcrResult> _processWithAzureCognitive(
      XFile imageFile) async {
    try {
      debugPrint('🔍 Using Azure Cognitive Services...');

      final bytes = await imageFile.readAsBytes();

      final response = await http.post(
        Uri.parse('$_azureEndpoint/vision/v3.2/ocr'),
        headers: {
          'Ocp-Apim-Subscription-Key': _azureApiKey,
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = _extractTextFromAzureResponse(data);
        final extractedFields =
            ocr_result.FieldDataPatterns.extractFields(text);

        return ocr_result.OcrResult(
          rawText: text,
          scanTimestamp: DateTime.now(),
          extractedFields: extractedFields,
          confidence: 0.85,
        );
      }

      throw Exception(
          'Azure Cognitive Services failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Azure Cognitive Services error: $e');
      rethrow;
    }
  }

  /// Extract text from Azure OCR response
  String _extractTextFromAzureResponse(Map<String, dynamic> data) {
    final regions = data['regions'] as List? ?? [];
    final textParts = <String>[];

    for (final region in regions) {
      final lines = region['lines'] as List? ?? [];
      for (final line in lines) {
        final words = line['words'] as List? ?? [];
        final lineText = words.map((word) => word['text']).join(' ');
        textParts.add(lineText);
      }
    }

    return textParts.join('\n');
  }

  /// Simulate Tesseract processing for demo purposes
  Future<String> _simulateTesseractProcessing(Uint8List bytes) async {
    // In a real implementation, this would call Tesseract.js
    // For now, return mock data for demonstration
    await Future.delayed(const Duration(seconds: 2));

    // Return actual table-structured data that matches your log format
    return '''
    0000    0100    0200    0300    0400    0500    0600    0700    0800    0900    1000    1100
    VAPOR INLET FLOW RATE    2000    2100    2200    2300    2400    2500    2600    2700    2800    2900    3000    3100
    DILUTION AIR    100    110    120    130    140    150    160    170    180    190    200    210
    COMBUSTION AIR    50    55    60    65    70    75    80    85    90    95    100    105
    EXHAUST TEMPERATURE    1463    1470    1475    1480    1485    1490    1495    1500    1505    1510    1515    1520
    INLET PPM    442.0    445.0    448.0    451.0    454.0    457.0    460.0    463.0    466.0    469.0    472.0    475.0
    OUTLET PPM    1.4    1.5    1.6    1.7    1.8    1.9    2.0    2.1    2.2    2.3    2.4    2.5
    SPHERE PRESSURE    7.0    7.1    7.2    7.3    7.4    7.5    7.6    7.7    7.8    7.9    8.0    8.1
    TOTALIZER READING    5148583    5148600    5148620    5148640    5148660    5148680    5148700    5148720    5148740    5148760    5148780    5148800
    ''';
  }

  /// Map field type from our system to OCR result format
  ocr_result.FieldType _mapFieldType(FieldType fieldType) {
    switch (fieldType) {
      case FieldType.temperature:
        return ocr_result.FieldType.temperature;
      case FieldType.pressure:
        return ocr_result.FieldType.pressure;
      case FieldType.flowRate:
        return ocr_result.FieldType.flowRate;
      case FieldType.concentration:
        return ocr_result.FieldType.ppm;
      case FieldType.time:
        return ocr_result.FieldType.time;
      case FieldType.totalizer:
        return ocr_result.FieldType.text;
      case FieldType.numeric:
        return ocr_result.FieldType.text;
      case FieldType.text:
      default:
        return ocr_result.FieldType.text;
    }
  }

  /// Convert OCR result to thermal reading data structure
  Map<String, dynamic> mapToThermalReading(ocr_result.OcrResult ocrResult) {
    final data = <String, dynamic>{};

    for (final field in ocrResult.extractedFields) {
      switch (field.fieldName.toLowerCase()) {
        case 'temperature':
          final value = field.typedValue as double?;
          if (value != null) {
            data['inletReading'] = value;
          }
          break;

        case 'ppm':
          final value = field.typedValue as double?;
          if (value != null) {
            data['toInletReadingH2S'] = value;
          }
          break;

        case 'flow rate':
          final value = field.typedValue as double?;
          if (value != null) {
            switch (field.unit.toUpperCase()) {
              case 'FPM':
                data['vaporInletFlowRateFPM'] = value;
                break;
              case 'BBL':
                data['vaporInletFlowRateBBL'] = value;
                break;
              case 'CFM':
                data['combustionAirFlowRate'] = value;
                break;
              case 'GPM':
                data['tankRefillFlowRate'] = value;
                break;
            }
          }
          break;

        case 'pressure':
          final value = field.typedValue as double?;
          if (value != null && field.unit.toLowerCase().contains('hg')) {
            data['vacuumAtTankVaporOutlet'] = value;
          }
          break;

        case 'hour':
          final value = field.typedValue as int?;
          if (value != null) {
            data['hour'] = value;
          }
          break;
      }
    }

    // Add OCR metadata
    data['ocrRawText'] = ocrResult.rawText;
    data['ocrConfidence'] = ocrResult.confidence;
    data['ocrTimestamp'] = ocrResult.scanTimestamp.toIso8601String();

    return data;
  }
}
