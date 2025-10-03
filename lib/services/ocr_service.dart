import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ocr_result.dart';

/// Service for OCR text recognition from images
class OcrService {
  static final _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  final _textRecognizer = TextRecognizer();
  final _imagePicker = ImagePicker();

  /// Dispose resources when done
  void dispose() {
    _textRecognizer.close();
  }

  /// Check and request camera permissions
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  /// Take photo from camera
  Future<File?> takePhoto() async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        throw Exception('Camera permission denied');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85, // Good balance of quality and file size
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error taking photo: $e');
      rethrow;
    }
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error picking from gallery: $e');
      rethrow;
    }
  }

  /// Extract text from image using ML Kit
  Future<OcrResult> extractTextFromImage(File imageFile) async {
    try {
      debugPrint('🔍 Starting OCR on image: ${imageFile.path}');
      
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      debugPrint('📄 Raw OCR text: ${recognizedText.text}');
      
      // Extract structured data from raw text
      final extractedFields = FieldDataPatterns.extractFields(recognizedText.text);
      
      // Calculate overall confidence (average of block confidences)
      double totalConfidence = 0.0;
      int blockCount = 0;
      
      for (final block in recognizedText.blocks) {
        // ML Kit doesn't provide confidence directly, so we estimate based on text quality
        totalConfidence += _estimateConfidence(block.text);
        blockCount++;
      }
      
      final avgConfidence = blockCount > 0 ? totalConfidence / blockCount : 0.0;

      final result = OcrResult(
        rawText: recognizedText.text,
        scanTimestamp: DateTime.now(),
        extractedFields: extractedFields,
        confidence: avgConfidence,
      );

      debugPrint('✅ OCR completed. Found ${extractedFields.length} fields');
      for (final field in extractedFields) {
        debugPrint('  📊 ${field.fieldName}: ${field.value} ${field.unit}');
      }

      return result;
    } catch (e) {
      debugPrint('❌ OCR extraction failed: $e');
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Estimate confidence based on text characteristics
  double _estimateConfidence(String text) {
    if (text.isEmpty) return 0.0;
    
    double confidence = 0.5; // Base confidence
    
    // Higher confidence for text with numbers (likely data)
    if (RegExp(r'\d').hasMatch(text)) {
      confidence += 0.2;
    }
    
    // Higher confidence for text with common units
    if (RegExp(r'(°F|°C|ppm|PPM|CFM|FPM|BBL|GPM|PSI|inHg)', caseSensitive: false).hasMatch(text)) {
      confidence += 0.3;
    }
    
    // Lower confidence for very short text
    if (text.length < 3) {
      confidence -= 0.2;
    }
    
    // Higher confidence for longer, structured text
    if (text.length > 10 && text.contains(' ')) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Process image with pre-processing for better OCR results
  Future<OcrResult> processImageWithPreprocessing(File imageFile) async {
    try {
      // For now, we'll use the basic extraction
      // In the future, you could add image preprocessing here:
      // - Brightness/contrast adjustment
      // - Noise reduction
      // - Edge enhancement
      // - Rotation correction
      
      return await extractTextFromImage(imageFile);
    } catch (e) {
      debugPrint('❌ Error processing image: $e');
      rethrow;
    }
  }

  /// Convert OCR result to ThermalReading data structure
  Map<String, dynamic> mapToThermalReading(OcrResult ocrResult) {
    final data = <String, dynamic>{};
    
    for (final field in ocrResult.extractedFields) {
      switch (field.fieldName.toLowerCase()) {
        case 'temperature':
          // Map to appropriate temperature field based on context
          if (field.value.isNotEmpty) {
            final value = field.typedValue as double?;
            if (value != null) {
              // You might need to determine which temperature field this is
              // For now, we'll map to inlet reading
              data['inletReading'] = value;
            }
          }
          break;
          
        case 'ppm':
          final value = field.typedValue as double?;
          if (value != null) {
            data['toInletReadingH2S'] = value; // Assuming H2S PPM
          }
          break;
          
        case 'flow rate':
          final value = field.typedValue as double?;
          if (value != null) {
            // Map based on unit
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
    
    // Add metadata
    data['ocrRawText'] = ocrResult.rawText;
    data['ocrConfidence'] = ocrResult.confidence;
    data['ocrTimestamp'] = ocrResult.scanTimestamp.toIso8601String();
    
    return data;
  }
}