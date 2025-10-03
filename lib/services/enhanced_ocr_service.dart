import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ocr_result.dart';

/// Stub Enhanced OCR Service for demo builds
class EnhancedOcrService {
  static final _instance = EnhancedOcrService._internal();
  factory EnhancedOcrService() => _instance;
  EnhancedOcrService._internal();

  final _imagePicker = ImagePicker();

  /// Dispose resources when done
  void dispose() {
    // Stub implementation
  }

  /// Check and request camera permissions
  Future<bool> requestCameraPermission() async {
    // Return true for demo
    return true;
  }

  /// Capture image from camera
  Future<File?> captureImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  /// Select image from gallery
  Future<File?> selectImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error selecting image: $e');
      return null;
    }
  }

  /// Process image and extract thermal log data (stub)
  Future<Map<String, dynamic>> processImageForThermalLog(File imageFile) async {
    // Return sample data for demo
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing
    
    return {
      'success': true,
      'extractedData': {
        'inletReading': 85.5,
        'outletReading': 12.3,
        'exhaustTemperature': 650.0,
        'vaporInletFlowRateFPM': 1200.0,
        'vacuumAtTankVaporOutlet': 2.5,
        'totalizer': 1000.0,
      },
      'confidence': 0.85,
      'message': 'Demo OCR extraction completed',
    };
  }

  /// Take photo (alias for captureImageFromCamera)
  Future<XFile?> takePhoto() async {
    final file = await captureImageFromCamera();
    return file != null ? XFile(file.path) : null;
  }

  /// Pick from gallery (alias for selectImageFromGallery)
  Future<XFile?> pickFromGallery() async {
    final file = await selectImageFromGallery();
    return file != null ? XFile(file.path) : null;
  }

  /// Process image (wrapper for processImageForThermalLog)
  Future<OcrResult> processImage(XFile imageFile) async {
    final file = File(imageFile.path);
    final result = await processImageForThermalLog(file);
    
    return OcrResult(
      rawText: result['message'] ?? 'OCR processing completed',
      scanTimestamp: DateTime.now(),
      extractedFields: [],
      confidence: (result['confidence'] ?? 0.0) as double,
    );
  }

  /// Map OCR result to thermal reading format
  Map<String, dynamic> mapToThermalReading(OcrResult ocrResult) {
    final Map<String, dynamic> thermalData = {};
    
    for (final field in ocrResult.extractedFields) {
      thermalData[field.fieldName] = field.typedValue;
    }
    
    return thermalData;
  }
}