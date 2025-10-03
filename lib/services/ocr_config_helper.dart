import 'ocr_engine_service.dart';

/// Helper class for configuring OCR engines with predefined settings
class OcrConfigHelper {
  /// Get Tesseract configuration optimized for thermal log data
  static OcrConfig getTesseractConfig({
    String language = 'eng',
    String? characterWhitelist,
    Map<String, dynamic>? customParams,
  }) {
    return OcrConfig(
      engine: OcrEngine.tesseract,
      language: language,
      characterWhitelist: characterWhitelist ?? _getDefaultCharacterWhitelist(),
      customParams: customParams ?? _getDefaultTesseractParams(),
    );
  }

  /// Get API configuration for HandwritingOCR.com
  static OcrConfig getApiConfig({
    String? apiKey,
    String language = 'en',
    Map<String, dynamic>? customParams,
  }) {
    return OcrConfig(
      engine: OcrEngine.api,
      apiKey: apiKey,
      language: language,
      customParams: customParams,
    );
  }

  /// Get ML Kit configuration (for future use)
  static OcrConfig getMlKitConfig({
    String language = 'en',
    Map<String, dynamic>? customParams,
  }) {
    return OcrConfig(
      engine: OcrEngine.mlKit,
      language: language,
      customParams: customParams,
    );
  }

  /// Get default character whitelist for thermal log data
  static String _getDefaultCharacterWhitelist() {
    return '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz°FPSIGPM:.,/-() ';
  }

  /// Get default Tesseract parameters for better accuracy
  static Map<String, dynamic> _getDefaultTesseractParams() {
    return {
      'psm': 6, // Assume uniform block of text
      'oem': 3, // Default OCR Engine Mode
      'tessedit_char_blacklist': '|\\', // Exclude problematic characters
      'preserve_interword_spaces': '1',
    };
  }

  /// Get configuration for specific use cases
  static OcrConfig getConfigForUseCase(String useCase) {
    switch (useCase.toLowerCase()) {
      case 'thermal_logs':
        return getTesseractConfig(
          characterWhitelist:
              '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz°FPSIGPM:.,/-() ',
        );
      case 'handwritten_notes':
        return getTesseractConfig(
          characterWhitelist:
              '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.,!?()-\'" ',
        );
      case 'api_fallback':
        return getApiConfig();
      default:
        return getTesseractConfig();
    }
  }

  /// Quick setup for the OCR service with a specific configuration
  static void setupOcrService(OcrConfig config) {
    final service = OcrEngineService();
    service.setConfig(config);
  }

  /// Quick setup for thermal log OCR
  static void setupForThermalLogs() {
    setupOcrService(getConfigForUseCase('thermal_logs'));
  }

  /// Quick setup for handwritten notes OCR
  static void setupForHandwrittenNotes() {
    setupOcrService(getConfigForUseCase('handwritten_notes'));
  }

  /// Quick setup for API fallback
  static void setupForApiFallback() {
    setupOcrService(getConfigForUseCase('api_fallback'));
  }
}
