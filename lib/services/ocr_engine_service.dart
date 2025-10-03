import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ocr_result.dart';

/// Enum for different OCR engines
enum OcrEngine {
  tesseract, // Local Tesseract OCR
  api, // HandwritingOCR.com API
  mlKit, // Google ML Kit (mobile only)
}

/// Configuration for OCR engines
class OcrConfig {
  final OcrEngine engine;
  final String? apiKey;
  final String? language;
  final String? characterWhitelist;
  final Map<String, dynamic>? customParams;

  const OcrConfig({
    required this.engine,
    this.apiKey,
    this.language = 'eng',
    this.characterWhitelist,
    this.customParams,
  });
}

/// Modular OCR service that can switch between different engines
class OcrEngineService {
  static final _instance = OcrEngineService._internal();
  factory OcrEngineService() => _instance;
  OcrEngineService._internal();

  final _imagePicker = ImagePicker();

  // Default configuration
  OcrConfig _config = const OcrConfig(
    engine: OcrEngine.tesseract,
    language: 'eng',
  );

  // API configuration (for fallback)
  static const String _apiUrl = 'https://api.handwritingocr.com/v1/ocr';
  static const String _proxyUrl = 'http://localhost:3001/api/ocr';
  static const String _apiKey =
      '823|LglKRVdLG1ATRvrlNawKdHpYLeWZtkT3mmFXTUnB965ff240';

  // Image processing configuration
  static const int _maxImageWidth = 800;
  static const int _jpegQuality = 85;

  /// Set the OCR configuration
  void setConfig(OcrConfig config) {
    _config = config;
    debugPrint('🔧 OCR Engine configured: ${config.engine}');
  }

  /// Get current OCR configuration
  OcrConfig get config => _config;

  /// Main function that handles the complete OCR flow
  /// Returns the raw OCR text result from the selected engine
  Future<String> processImageWithOcr({
    ImageSource source = ImageSource.camera,
    bool enablePreprocessing = true,
    Rect? cropRect,
    OcrConfig? overrideConfig,
  }) async {
    final config = overrideConfig ?? _config;

    try {
      debugPrint('📸 Starting OCR flow with engine: ${config.engine}');

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

      // Step 3: Run OCR with selected engine
      final String ocrResult = await _runOcrEngine(processedImageBytes, config);

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
            overrideConfig: config,
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

      // Step 3: Enhance for better OCR recognition
      processedImage = _enhanceImageForOcr(processedImage);
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

  /// Enhance image specifically for OCR recognition
  img.Image _enhanceImageForOcr(img.Image image) {
    // Convert to grayscale for better OCR
    img.Image grayscale = img.grayscale(image);

    // Apply additional enhancements based on OCR engine
    switch (_config.engine) {
      case OcrEngine.tesseract:
        // Tesseract works best with high contrast and sharp edges
        return _enhanceForTesseract(grayscale);
      case OcrEngine.api:
        // API works well with grayscale
        return grayscale;
      case OcrEngine.mlKit:
        // ML Kit can handle color images well
        return image;
    }
  }

  /// Enhance image specifically for Tesseract OCR
  img.Image _enhanceForTesseract(img.Image image) {
    // Tesseract works best with:
    // 1. High contrast (black text on white background)
    // 2. Sharp edges
    // 3. Clean, noise-free images

    // Apply contrast enhancement - using the correct API with named parameter
    img.Image enhanced = img.contrast(image, contrast: 1.5);

    // Note: sharpen method is not available in this version of the image package
    // The grayscale conversion already helps with OCR recognition

    return enhanced;
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

  /// Run OCR with the selected engine
  Future<String> _runOcrEngine(Uint8List imageBytes, OcrConfig config) async {
    switch (config.engine) {
      case OcrEngine.tesseract:
        return await _runTesseractOcr(imageBytes, config);
      case OcrEngine.api:
        return await _runApiOcr(imageBytes, config);
      case OcrEngine.mlKit:
        return await _runMlKitOcr(imageBytes, config);
    }
  }

  /// Run Tesseract OCR locally
  Future<String> _runTesseractOcr(
      Uint8List imageBytes, OcrConfig config) async {
    try {
      debugPrint('🔍 Running Tesseract OCR...');

      // For web, Tesseract OCR might not be available
      if (kIsWeb) {
        throw Exception('Tesseract OCR is not available on web platform');
      }

      // Save image bytes to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(imageBytes);

      // Run Tesseract OCR with file path
      final String result = await TesseractOcr.extractText(tempFile.path);

      // Clean up temporary file
      await tempFile.delete();

      debugPrint('📄 Tesseract OCR completed: ${result.length} characters');
      return result.trim();
    } catch (e) {
      debugPrint('❌ Tesseract OCR failed: $e');
      rethrow;
    }
  }

  /// Run API-based OCR (HandwritingOCR.com)
  Future<String> _runApiOcr(Uint8List imageBytes, OcrConfig config) async {
    try {
      debugPrint('🌐 Running API OCR...');

      // Convert to base64
      final String base64Image = base64Encode(imageBytes);

      // Use proxy server for web, direct API for mobile
      const String apiEndpoint = kIsWeb ? _proxyUrl : _apiUrl;
      final Map<String, String> headers = kIsWeb
          ? {'Content-Type': 'application/json'}
          : {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.apiKey ?? _apiKey}',
            };

      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: headers,
            body: jsonEncode({
              'base64Image': base64Image,
              'language': config.language ?? 'en',
              'outputFormat': 'text',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        final String ocrText = result['text'] ?? result['result'] ?? '';

        debugPrint('📄 API OCR completed: ${ocrText.length} characters');
        return ocrText;
      } else {
        throw Exception(
            'API OCR error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ API OCR failed: $e');
      rethrow;
    }
  }

  /// Run ML Kit OCR (mobile only)
  Future<String> _runMlKitOcr(Uint8List imageBytes, OcrConfig config) async {
    try {
      debugPrint('📱 Running ML Kit OCR...');

      // This would require implementing ML Kit OCR
      // For now, we'll throw an exception to indicate it's not implemented
      throw Exception('ML Kit OCR not implemented yet');
    } catch (e) {
      debugPrint('❌ ML Kit OCR failed: $e');
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
      confidence: 0.8, // Default confidence
    );
  }
}
