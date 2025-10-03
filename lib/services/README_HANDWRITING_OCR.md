> **DEPRECATED DOC** — The canonical docs live in [/docs/BigPicture.md](../docs/BigPicture.md).
# HandwritingOCR.com Integration

This module provides a complete Flutter/Dart solution for capturing, preprocessing, and OCR processing images using the HandwritingOCR.com API.

## Features

- 📸 **Image Capture**: Camera and gallery image selection
- 🔧 **Image Preprocessing**: Automatic enhancement for better OCR
- 🌐 **API Integration**: Direct integration with HandwritingOCR.com
- 📊 **Result Parsing**: Structured data extraction from OCR text
- 🔄 **Fallback Handling**: Graceful error handling and retry mechanisms

## Setup

### 1. Dependencies

Add the required dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  image_picker: ^1.0.4
  permission_handler: ^11.0.1
  http: ^1.1.0
  image: ^4.1.3
  flutter_image_compress: ^2.1.0
```

### 2. API Key Configuration

1. Sign up for an account at [HandwritingOCR.com](https://www.handwritingocr.com)
2. Get your API key from the dashboard
3. Replace `YOUR_HANDWRITING_OCR_API_KEY` in `lib/services/handwriting_ocr_service.dart`

```dart
static const String _apiKey = 'your_actual_api_key_here';
```

### 3. Permissions

For Android, add camera permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

For iOS, add camera permissions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture paper logs for OCR processing.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images for OCR processing.</string>
```

## Usage

### Basic Usage

```dart
import 'package:your_app/services/handwriting_ocr_service.dart';
import 'package:your_app/models/ocr_result.dart';

// Get the service instance
final ocrService = HandwritingOcrService();

// Process an image with OCR
try {
  final String ocrText = await ocrService.processImageWithOcr(
    source: ImageSource.camera, // or ImageSource.gallery
    enablePreprocessing: true,
  );
  
  // Convert to structured result
  final OcrResult result = ocrText.toOcrResult();
  
  print('Raw text: ${result.rawText}');
  print('Extracted fields: ${result.extractedFields.length}');
  
} catch (e) {
  print('OCR failed: $e');
}
```

### Advanced Usage with Custom Preprocessing

```dart
// Custom crop rectangle (optional)
final cropRect = Rect.fromLTWH(100, 100, 300, 400);

final String ocrText = await ocrService.processImageWithOcr(
  source: ImageSource.camera,
  enablePreprocessing: true,
  cropRect: cropRect,
);
```

### Using the Widget Components

```dart
import 'package:your_app/widgets/ocr_capture_widget.dart';

// In your widget
OcrCaptureWidget(
  onOcrComplete: (OcrResult result) {
    // Handle successful OCR
    print('OCR completed: ${result.rawText}');
  },
  onError: (String error) {
    // Handle errors
    print('OCR error: $error');
  },
)

// Display results
OcrResultDisplay(
  ocrResult: result,
  onRetry: () {
    // Retry OCR
  },
)
```

## Image Preprocessing Pipeline

The service automatically applies the following preprocessing steps:

1. **Crop** (optional): Crop to specified rectangle
2. **Resize**: Scale to max width of 800px while maintaining aspect ratio
3. **Enhance**: 
   - Convert to grayscale
   - Enhance contrast (1.2x)
   - Adjust brightness (+10%)
   - Apply sharpening (0.5x)
4. **Compress**: Convert to JPEG with 85% quality
5. **Encode**: Convert to base64 for API transmission

## API Response Handling

The service expects the following response format from HandwritingOCR.com:

```json
{
  "text": "extracted text content",
  "confidence": 0.95
}
```

If the API response format differs, update the `_sendToHandwritingOcr` method accordingly.

## Error Handling and Fallbacks

The service includes several fallback mechanisms:

1. **Preprocessing Fallback**: If preprocessing fails, retry with original image
2. **API Timeout**: 30-second timeout with retry option
3. **Network Errors**: Graceful handling with user-friendly error messages
4. **Image Validation**: Checks for minimum/maximum image dimensions

## Extracted Field Types

The service automatically extracts and categorizes the following field types:

- **Temperature**: Values with °F, °C, F, C units
- **PPM**: Parts per million values
- **Flow Rate**: CFM, FPM, BBL, GPM values
- **Pressure**: PSI, inHg, bar values
- **Hour**: Time hour values
- **Time**: Time stamps in various formats

## Configuration Options

You can customize the preprocessing parameters in `HandwritingOcrService`:

```dart
// Image processing configuration
static const int _maxImageWidth = 800;
static const int _jpegQuality = 85;
static const double _minContrast = 1.2;
static const double _brightnessAdjustment = 0.1;
```

## Troubleshooting

### Common Issues

1. **Camera Permission Denied**
   - Ensure permissions are properly configured
   - Check if user manually denied permissions

2. **API Key Invalid**
   - Verify your HandwritingOCR.com API key
   - Check API key permissions and usage limits

3. **Image Processing Fails**
   - Ensure image is not corrupted
   - Check image dimensions (minimum 100x100, maximum 4000x4000)

4. **Network Timeout**
   - Check internet connectivity
   - Verify HandwritingOCR.com service status

### Debug Logging

The service includes comprehensive debug logging. Enable debug mode to see detailed processing steps:

```dart
// Debug messages will appear in console
// Look for emoji-prefixed messages:
// 📸 Starting OCR flow
// 🔧 Starting image preprocessing
// ✂️ Image cropped
// 📏 Image resized
// ✨ Image enhanced
// 🗜️ Image compressed
// 🌐 Sending to API
// 📄 OCR text received
// ✅ OCR completed
// ❌ Error messages
```

## Performance Considerations

- **Image Size**: Larger images take longer to process
- **Network**: API calls require internet connectivity
- **Memory**: Image processing uses significant memory for large images
- **Battery**: Camera usage and image processing consume battery

## Security Notes

- API keys should be stored securely (consider using environment variables)
- Images are sent to HandwritingOCR.com servers for processing
- Consider implementing local OCR fallback for sensitive data

## Example Implementation

See `lib/screens/ocr_demo_screen.dart` for a complete example implementation with UI components.

## Support

For issues with:
- **HandwritingOCR.com API**: Contact their support
- **Flutter/Dart implementation**: Check this documentation
- **Image processing**: Review preprocessing parameters 