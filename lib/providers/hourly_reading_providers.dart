import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hourly_reading_models.dart';
import '../services/hourly_log_parser.dart';

/// Provider for the hourly log parser service
final hourlyLogParserProvider = Provider<HourlyLogParser>((ref) {
  return HourlyLogParser();
});

/// Provider for storing parsed hourly readings
final hourlyReadingsProvider = StateNotifierProvider<HourlyReadingsNotifier, Map<String, HourlyReading>>((ref) {
  return HourlyReadingsNotifier();
});

/// Provider for the current selected hour
final selectedHourProvider = StateProvider<String?>((ref) => null);

/// Provider for OCR parsing state
final ocrParsingStateProvider = StateNotifierProvider<OcrParsingStateNotifier, OcrParsingState>((ref) {
  return OcrParsingStateNotifier();
});

/// Provider for form pre-fill data
final formPreFillProvider = StateProvider<HourlyReading?>((ref) => null);

/// State notifier for managing hourly readings
class HourlyReadingsNotifier extends StateNotifier<Map<String, HourlyReading>> {
  HourlyReadingsNotifier() : super({});

  /// Add or update a reading for a specific hour
  void setReading(String hour, HourlyReading reading) {
    state = {
      ...state,
      hour: reading,
    };
  }

  /// Get reading for specific hour
  HourlyReading? getReading(String hour) {
    return state[hour];
  }

  /// Remove reading for specific hour
  void removeReading(String hour) {
    final newState = Map<String, HourlyReading>.from(state);
    newState.remove(hour);
    state = newState;
  }

  /// Clear all readings
  void clearAll() {
    state = {};
  }

  /// Get readings with minimum confidence threshold
  Map<String, HourlyReading> getHighConfidenceReadings(double minConfidence) {
    return Map.fromEntries(
      state.entries.where((entry) => entry.value.overallConfidence >= minConfidence),
    );
  }

  /// Get statistics about readings quality
  ReadingStatistics getStatistics() {
    if (state.isEmpty) {
      return const ReadingStatistics(
        totalReadings: 0,
        highQualityReadings: 0,
        averageConfidence: 0.0,
        completedHours: [],
      );
    }

    final readings = state.values.toList();
    final highQuality = readings.where((r) => r.isHighQuality).length;
    final avgConfidence = readings
        .map((r) => r.overallConfidence)
        .reduce((a, b) => a + b) / readings.length;

    return ReadingStatistics(
      totalReadings: readings.length,
      highQualityReadings: highQuality,
      averageConfidence: avgConfidence,
      completedHours: state.keys.toList()..sort(),
    );
  }
}

/// State notifier for OCR parsing operations
class OcrParsingStateNotifier extends StateNotifier<OcrParsingState> {
  OcrParsingStateNotifier() : super(const OcrParsingState.idle());

  /// Start parsing operation
  void startParsing(String hour, String ocrText) {
    state = OcrParsingState.parsing(hour: hour, ocrText: ocrText);
  }

  /// Complete parsing with result
  void completeWith(HourlyReading result) {
    state = OcrParsingState.completed(result: result);
  }

  /// Fail parsing with error
  void failWith(String error) {
    state = OcrParsingState.error(error: error);
  }

  /// Reset to idle state
  void reset() {
    state = const OcrParsingState.idle();
  }
}

/// OCR parsing state
sealed class OcrParsingState {
  const OcrParsingState();

  const factory OcrParsingState.idle() = _Idle;
  const factory OcrParsingState.parsing({
    required String hour,
    required String ocrText,
  }) = _Parsing;
  const factory OcrParsingState.completed({
    required HourlyReading result,
  }) = _Completed;
  const factory OcrParsingState.error({
    required String error,
  }) = _Error;

  bool get isIdle => this is _Idle;
  bool get isParsing => this is _Parsing;
  bool get isCompleted => this is _Completed;
  bool get isError => this is _Error;

  T when<T>({
    required T Function() idle,
    required T Function(String hour, String ocrText) parsing,
    required T Function(HourlyReading result) completed,
    required T Function(String error) error,
  }) {
    return switch (this) {
      _Idle() => idle(),
      _Parsing(:final hour, :final ocrText) => parsing(hour, ocrText),
      _Completed(:final result) => completed(result),
      _Error(:final error) => error(error),
    };
  }
}

class _Idle extends OcrParsingState {
  const _Idle();
}

class _Parsing extends OcrParsingState {
  final String hour;
  final String ocrText;

  const _Parsing({required this.hour, required this.ocrText});
}

class _Completed extends OcrParsingState {
  final HourlyReading result;

  const _Completed({required this.result});
}

class _Error extends OcrParsingState {
  final String error;

  const _Error({required this.error});
}

/// Statistics about reading quality
class ReadingStatistics {
  final int totalReadings;
  final int highQualityReadings;
  final double averageConfidence;
  final List<String> completedHours;

  const ReadingStatistics({
    required this.totalReadings,
    required this.highQualityReadings,
    required this.averageConfidence,
    required this.completedHours,
  });

  double get qualityPercentage => 
      totalReadings == 0 ? 0.0 : (highQualityReadings / totalReadings) * 100;

  bool get isAcceptableQuality => averageConfidence >= 0.7 && qualityPercentage >= 60;
}

/// Extension methods for easier access
extension HourlyReadingProvidersX on WidgetRef {
  
  /// Parse OCR text for a specific hour
  Future<void> parseOcrForHour(String hour, String ocrText) async {
    final parser = read(hourlyLogParserProvider);
    final parsingNotifier = read(ocrParsingStateProvider.notifier);
    final readingsNotifier = read(hourlyReadingsProvider.notifier);

    try {
      parsingNotifier.startParsing(hour, ocrText);
      
      final result = await parser.parseHourlyReading(ocrText, hour);
      
      parsingNotifier.completeWith(result);
      readingsNotifier.setReading(hour, result);
      
      // Set as form pre-fill data if quality is acceptable
      if (result.isAcceptable) {
        read(formPreFillProvider.notifier).state = result;
      }
      
    } catch (e) {
      parsingNotifier.failWith(e.toString());
    }
  }

  /// Get reading for current selected hour
  HourlyReading? getCurrentHourReading() {
    final selectedHour = read(selectedHourProvider);
    if (selectedHour == null) return null;
    
    return read(hourlyReadingsProvider)[selectedHour];
  }

  /// Pre-fill form with OCR data
  void preFillFormWithOcr(HourlyReading reading) {
    read(formPreFillProvider.notifier).state = reading;
  }

  /// Clear form pre-fill data
  void clearFormPreFill() {
    read(formPreFillProvider.notifier).state = null;
  }
}