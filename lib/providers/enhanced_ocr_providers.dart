import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/enhanced_ocr_service.dart';
import '../services/enhanced_ocr_service_backup.dart';

/// Provider for the enhanced OCR service
final enhancedOcrServiceProvider = Provider<EnhancedOcrService>((ref) {
  return EnhancedOcrService();
});

/// Provider for enhanced OCR results
final enhancedOcrResultProvider =
    StateProvider<EnhancedOcrResult?>((ref) => null);

/// Provider for enhanced OCR loading state
final enhancedOcrLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for enhanced OCR processing state
final enhancedOcrProcessingStateProvider = StateNotifierProvider<
    EnhancedOcrProcessingStateNotifier, EnhancedOcrProcessingState>((ref) {
  return EnhancedOcrProcessingStateNotifier();
});

/// Provider for debug mode toggle
final ocrDebugModeProvider = StateProvider<bool>((ref) => true);

/// Provider for strict mode toggle
final ocrStrictModeProvider = StateProvider<bool>((ref) => true);

/// Provider for processing statistics
final ocrProcessingStatsProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// Enhanced OCR processing state
class EnhancedOcrProcessingState {
  final bool isProcessing;
  final String? currentStep;
  final double? progress;
  final String? error;
  final Map<String, dynamic>? debugInfo;

  const EnhancedOcrProcessingState({
    this.isProcessing = false,
    this.currentStep,
    this.progress,
    this.error,
    this.debugInfo,
  });

  const EnhancedOcrProcessingState.processing({
    required this.currentStep,
    this.progress,
  })  : isProcessing = true,
        error = null,
        debugInfo = null;

  const EnhancedOcrProcessingState.error({
    required this.error,
  })  : isProcessing = false,
        currentStep = null,
        progress = null,
        debugInfo = null;

  const EnhancedOcrProcessingState.completed({
    this.debugInfo,
  })  : isProcessing = false,
        currentStep = null,
        progress = null,
        error = null;

  const EnhancedOcrProcessingState.idle()
      : isProcessing = false,
        currentStep = null,
        progress = null,
        error = null,
        debugInfo = null;
}

/// State notifier for enhanced OCR processing
class EnhancedOcrProcessingStateNotifier
    extends StateNotifier<EnhancedOcrProcessingState> {
  EnhancedOcrProcessingStateNotifier()
      : super(const EnhancedOcrProcessingState.idle());

  /// Start processing
  void startProcessing(String step) {
    state = EnhancedOcrProcessingState.processing(currentStep: step);
  }

  /// Update progress
  void updateProgress(double progress) {
    if (state.isProcessing) {
      state = EnhancedOcrProcessingState.processing(
        currentStep: state.currentStep,
        progress: progress,
      );
    }
  }

  /// Complete processing
  void completeProcessing({Map<String, dynamic>? debugInfo}) {
    state = EnhancedOcrProcessingState.completed(debugInfo: debugInfo);
  }

  /// Set error
  void setError(String error) {
    state = EnhancedOcrProcessingState.error(error: error);
  }

  /// Reset to idle
  void reset() {
    state = const EnhancedOcrProcessingState.idle();
  }
}

/// Provider for validation results
final ocrValidationProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// Provider for hallucination flags
final hallucinationFlagsProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

/// Provider for manual review required state
final manualReviewRequiredProvider = StateProvider<bool>((ref) => false);

/// Provider for confidence threshold
final confidenceThresholdProvider = StateProvider<double>((ref) => 0.7);

/// Provider for OCR settings
final ocrSettingsProvider =
    StateNotifierProvider<OcrSettingsNotifier, OcrSettings>((ref) {
  return OcrSettingsNotifier();
});

/// OCR settings model
class OcrSettings {
  final bool debugMode;
  final bool strictMode;
  final double confidenceThreshold;
  final bool enableValidation;
  final bool enableAntiHallucination;
  final bool requireManualReview;

  const OcrSettings({
    this.debugMode = true,
    this.strictMode = true,
    this.confidenceThreshold = 0.7,
    this.enableValidation = true,
    this.enableAntiHallucination = true,
    this.requireManualReview = true,
  });

  OcrSettings copyWith({
    bool? debugMode,
    bool? strictMode,
    double? confidenceThreshold,
    bool? enableValidation,
    bool? enableAntiHallucination,
    bool? requireManualReview,
  }) {
    return OcrSettings(
      debugMode: debugMode ?? this.debugMode,
      strictMode: strictMode ?? this.strictMode,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      enableValidation: enableValidation ?? this.enableValidation,
      enableAntiHallucination:
          enableAntiHallucination ?? this.enableAntiHallucination,
      requireManualReview: requireManualReview ?? this.requireManualReview,
    );
  }

  Map<String, dynamic> toJson() => {
        'debugMode': debugMode,
        'strictMode': strictMode,
        'confidenceThreshold': confidenceThreshold,
        'enableValidation': enableValidation,
        'enableAntiHallucination': enableAntiHallucination,
        'requireManualReview': requireManualReview,
      };

  factory OcrSettings.fromJson(Map<String, dynamic> json) => OcrSettings(
        debugMode: json['debugMode'] ?? true,
        strictMode: json['strictMode'] ?? true,
        confidenceThreshold: json['confidenceThreshold']?.toDouble() ?? 0.7,
        enableValidation: json['enableValidation'] ?? true,
        enableAntiHallucination: json['enableAntiHallucination'] ?? true,
        requireManualReview: json['requireManualReview'] ?? true,
      );
}

/// State notifier for OCR settings
class OcrSettingsNotifier extends StateNotifier<OcrSettings> {
  OcrSettingsNotifier() : super(const OcrSettings());

  void updateSettings(OcrSettings newSettings) {
    state = newSettings;
  }

  void toggleDebugMode() {
    state = state.copyWith(debugMode: !state.debugMode);
  }

  void toggleStrictMode() {
    state = state.copyWith(strictMode: !state.strictMode);
  }

  void setConfidenceThreshold(double threshold) {
    state = state.copyWith(confidenceThreshold: threshold);
  }

  void toggleValidation() {
    state = state.copyWith(enableValidation: !state.enableValidation);
  }

  void toggleAntiHallucination() {
    state =
        state.copyWith(enableAntiHallucination: !state.enableAntiHallucination);
  }

  void toggleManualReview() {
    state = state.copyWith(requireManualReview: !state.requireManualReview);
  }
}
