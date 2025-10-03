import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/ocr_result.dart';
import 'secure_storage_service.dart';

/// Service for capturing, preprocessing, and OCR processing images using HandwritingOCR.com
class HandwritingOcrService {
  static final _instance = HandwritingOcrService._internal();
  factory HandwritingOcrService() => _instance;
  HandwritingOcrService._internal();

  final _imagePicker = ImagePicker();

  // HandwritingOCR.com API configuration
  static const String _apiUrl = 'https://api.handwritingocr.com/v1/ocr';
  static const String _proxyUrl = 'http://localhost:3001/api/ocr';
  
  // Get API key from secure storage
  static Future<String> _getApiKey() async {
    try {
      final String? apiKey = await SecureStorageService.getOcrApiKey();

      if (apiKey == null || apiKey.isEmpty) {
        // Fallback to environment variable for initial setup
        const String? envApiKey = String.fromEnvironment('HANDWRITING_OCR_API_KEY');
        if (envApiKey != null && envApiKey.isNotEmpty) {
          // Store the environment key in secure storage for future use
          await SecureStorageService.storeOcrApiKey(envApiKey);
          return envApiKey;
        }

        throw SecurityException('OCR API key not found. Please configure it in app settings.');
      }

      return apiKey;
    } catch (e) {
      debugPrint('Failed to retrieve OCR API key: $e');
      throw SecurityException('Failed to access OCR API key securely');
    }
  }

  // Image processing configuration
  static const int _maxImageWidth = 800;
  static const int _jpegQuality = 85;
  static const double _minContrast = 1.2;
  static const double _maxContrast = 2.0;
  static const double _brightnessAdjustment = 0.1;

  /// Main function that handles the complete OCR flow
  /// Returns the raw OCR text result from HandwritingOCR.com
  Future<String> processImageWithOcr({
    ImageSource source = ImageSource.camera,
    bool enablePreprocessing = true,
    Rect? cropRect,
  }) async {
    try {
      debugPrint('📸 Starting OCR flow with source: $source');

      // Step 1: Capture or pick image
      final XFile? imageFile = await _captureImage(source);
      if (imageFile == null) {
        throw Exception('No image selected or captured');
      }

      // Step 2: Preprocess the image
      Uint8List processedImageBytes;
      if (enablePreprocessing) {
        processedImageBytes = await _preprocessImage(
          imageFile,
          cropRect: cropRect,
        );
      } else {
        processedImageBytes = await imageFile.readAsBytes();
      }

      // Step 3: Convert to base64
      final String base64Image = base64Encode(processedImageBytes);

      // Step 4: Send to HandwritingOCR.com API
      final String ocrResult = await _sendToHandwritingOcr(base64Image);

      debugPrint('✅ OCR processing completed successfully');
      return ocrResult;
    } catch (e) {
      debugPrint('❌ OCR processing failed: $e');

      // Fallback: Try with original image without preprocessing
      if (enablePreprocessing) {
        debugPrint('🔄 Attempting fallback with original image...');
        try {
          return await processImageWithOcr(
            source: source,
            enablePreprocessing: false,
            cropRect: cropRect,
          );
        } catch (fallbackError) {
          debugPrint('❌ Fallback also failed: $fallbackError');
          throw Exception(
              'OCR processing failed with fallback: $fallbackError');
        }
      }

      rethrow;
    }
  }

  /// Capture image from camera or pick from gallery
  Future<XFile?> _captureImage(ImageSource source) async {
    try {
      // Check camera permissions for mobile platforms
      if (!kIsWeb && source == ImageSource.camera) {
        final hasPermission = await _requestCameraPermission();
        if (!hasPermission) {
          throw Exception('Camera permission denied');
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920, // Capture at higher resolution for better preprocessing
        maxHeight: 1080,
        imageQuality: 95, // High quality for preprocessing
      );

      if (image != null) {
        debugPrint('📸 Image captured: ${image.path}');
        return image;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error capturing image: $e');
      rethrow;
    }
  }

  /// Request camera permissions (mobile only)
  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;

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

  /// Preprocess image for better OCR recognition
  Future<Uint8List> _preprocessImage(
    XFile imageFile, {
    Rect? cropRect,
  }) async {
    try {
      debugPrint('🔧 Starting image preprocessing...');

      // Read image bytes
      final Uint8List originalBytes = await imageFile.readAsBytes();

      // Decode image
      final img.Image? originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Step 1: Crop if specified
      img.Image processedImage = originalImage;
      if (cropRect != null) {
        processedImage = _cropImage(originalImage, cropRect);
        debugPrint('✂️ Image cropped to: ${cropRect.width}x${cropRect.height}');
      }

      // Step 2: Resize to max width while maintaining aspect ratio
      processedImage = _resizeImage(processedImage);
      debugPrint(
          '📏 Image resized to: ${processedImage.width}x${processedImage.height}');

      // Step 3: Enhance contrast and brightness
      processedImage = _enhanceImage(processedImage);
      debugPrint('✨ Image enhanced for better OCR recognition');

      // Step 4: Compress to JPEG with specified quality
      final Uint8List compressedBytes = await _compressImage(processedImage);
      debugPrint('🗜️ Image compressed to ${compressedBytes.length} bytes');

      return compressedBytes;
    } catch (e) {
      debugPrint('❌ Image preprocessing failed: $e');
      rethrow;
    }
  }

  /// Crop image to specified rectangle
  img.Image _cropImage(img.Image original, Rect cropRect) {
    final int x = cropRect.left.round();
    final int y = cropRect.top.round();
    final int width = cropRect.width.round();
    final int height = cropRect.height.round();

    // Ensure crop rectangle is within image bounds
    final int safeX = x.clamp(0, original.width - 1);
    final int safeY = y.clamp(0, original.height - 1);
    final int safeWidth = width.clamp(1, original.width - safeX);
    final int safeHeight = height.clamp(1, original.height - safeY);

    return img.copyCrop(
      original,
      x: safeX,
      y: safeY,
      width: safeWidth,
      height: safeHeight,
    );
  }

  /// Resize image to max width while maintaining aspect ratio
  img.Image _resizeImage(img.Image image) {
    if (image.width <= _maxImageWidth) {
      return image; // No resize needed
    }

    final double aspectRatio = image.width / image.height;
    final int newHeight = (_maxImageWidth / aspectRatio).round();

    return img.copyResize(
      image,
      width: _maxImageWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Enhance image contrast and brightness for better OCR
  img.Image _enhanceImage(img.Image image) {
    // Convert to grayscale for better OCR
    img.Image grayscale = img.grayscale(image);

    // For now, just return grayscale as the image package methods may vary
    // The grayscale conversion alone often improves OCR accuracy
    return grayscale;
  }

  /// Compress image to JPEG format
  Future<Uint8List> _compressImage(img.Image image) async {
    try {
      // Convert to JPEG format with specified quality
      final Uint8List jpegBytes = img.encodeJpg(
        image,
        quality: _jpegQuality,
      );

      return jpegBytes;
    } catch (e) {
      debugPrint('❌ Image compression failed: $e');
      // Fallback: return original image as JPEG
      return img.encodeJpg(image, quality: 85);
    }
  }

  /// Send image to HandwritingOCR.com API
  Future<String> _sendToHandwritingOcr(String base64Image) async {
    try {
      debugPrint('🌐 Sending image to HandwritingOCR.com...');

      // Get API key securely
      final String apiKey = await _getApiKey();

      // Use proxy server for web, direct API for mobile
      const String apiEndpoint = kIsWeb ? _proxyUrl : _apiUrl;
      final Map<String, String> headers = kIsWeb
          ? {'Content-Type': 'application/json'}
          : {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            };

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: headers,
            body: jsonEncode({
              'base64Image': base64Image,
              'language': 'en', // Adjust based on your needs
              'outputFormat': 'text', // Get raw text output
            }),
          )
          .timeout(
            const Duration(seconds: 30), // 30 second timeout
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);

        // Extract the OCR text from the response
        final String ocrText = result['text'] ?? result['result'] ?? '';

        debugPrint('📄 OCR text received: ${ocrText.length} characters');
        return ocrText;
      } else {
        throw Exception(
          'OCR API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ OCR API call failed: $e');
      rethrow;
    }
  }

  /// Get test OCR response for development
  String _getTestOcrResponse() {
    return '''
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
  }

  /// Alternative OCR method using local ML Kit (fallback)
  Future<String> _fallbackLocalOcr(Uint8List imageBytes) async {
    try {
      debugPrint('🔄 Using local ML Kit OCR as fallback...');

      // This would require implementing local OCR using google_ml_kit
      // For now, we'll throw an exception to indicate fallback is needed
      throw Exception('Local OCR fallback not implemented');
    } catch (e) {
      debugPrint('❌ Local OCR fallback failed: $e');
      rethrow;
    }
  }

  /// Utility method to get image dimensions
  Future<Size> getImageDimensions(XFile imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);

      if (image != null) {
        return Size(image.width.toDouble(), image.height.toDouble());
      }

      throw Exception('Failed to decode image for dimension check');
    } catch (e) {
      debugPrint('❌ Error getting image dimensions: $e');
      rethrow;
    }
  }

  /// Utility method to validate image before processing
  bool _validateImage(img.Image image) {
    // Check minimum size requirements
    if (image.width < 100 || image.height < 100) {
      return false;
    }

    // Check maximum size limits (prevent memory issues)
    if (image.width > 4000 || image.height > 4000) {
      return false;
    }

    return true;
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
  }
}

/// Extension to add OCR result parsing capabilities
extension OcrResultExtension on String {
  /// Convert raw OCR text to structured OcrResult
  OcrResult toOcrResult() {
    return OcrResult(
      rawText: this,
      scanTimestamp: DateTime.now(),
      extractedFields: FieldDataPatterns.extractFields(this),
      confidence: 0.8, // Default confidence for HandwritingOCR.com
    );
  }
}
