import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/hourly_reading_models.dart';
import 'hourly_log_parser.dart';

/// AI-enhanced parser for complex and unstructured OCR scenarios
/// Provides fallback to cloud AI services when traditional parsing fails
class AiEnhancedParser {
  static final _instance = AiEnhancedParser._internal();
  factory AiEnhancedParser() => _instance;
  AiEnhancedParser._internal();

  final _traditionalParser = HourlyLogParser();
  
  // Configuration for AI services
  static const String _openAiApiKey = 'YOUR_OPENAI_API_KEY';
  static const String _anthropicApiKey = 'YOUR_ANTHROPIC_API_KEY';
  static const double _aiConfidenceThreshold = 0.6;
  static const int _maxRetries = 2;

  /// Enhanced parsing with AI fallback
  /// 
  /// Falls back to AI parsing when:
  /// 1. Traditional parsing confidence < threshold
  /// 2. No structured data found
  /// 3. Critical fields missing
  Future<HourlyReading> parseWithAiEnhancement(
    String ocrText,
    String targetHour, {
    bool forceAi = false,
    AiProvider preferredProvider = AiProvider.openai,
  }) async {
    debugPrint('🤖 Starting AI-enhanced parsing for hour: $targetHour');
    
    HourlyReading? traditionalResult;
    
    // Step 1: Try traditional parsing first (unless forced to use AI)
    if (!forceAi) {
      try {
        traditionalResult = await _traditionalParser.parseHourlyReading(ocrText, targetHour);
        debugPrint('📊 Traditional parsing: ${traditionalResult.validFieldCount} fields, ${(traditionalResult.overallConfidence * 100).toInt()}% confidence');
        
        // If traditional parsing is successful, return it
        if (_isParsingSuccessful(traditionalResult)) {
          debugPrint('✅ Traditional parsing successful, skipping AI');
          return traditionalResult;
        }
      } catch (e) {
        debugPrint('⚠️ Traditional parsing failed: $e');
      }
    }

    // Step 2: Fall back to AI parsing
    try {
      final aiResult = await _parseWithAi(
        ocrText, 
        targetHour, 
        preferredProvider,
        fallbackData: traditionalResult,
      );
      
      debugPrint('🤖 AI parsing: ${aiResult.validFieldCount} fields, ${(aiResult.overallConfidence * 100).toInt()}% confidence');
      
      // Step 3: Choose best result
      final bestResult = _chooseBestResult(traditionalResult, aiResult);
      debugPrint('🏆 Selected ${bestResult == aiResult ? 'AI' : 'traditional'} result');
      
      return bestResult;
      
    } catch (e) {
      debugPrint('❌ AI parsing failed: $e');
      
      // Return traditional result as fallback, or empty result
      return traditionalResult ?? _createEmptyReading(targetHour, ocrText, 'All parsing methods failed');
    }
  }

  /// Parse using AI service
  Future<HourlyReading> _parseWithAi(
    String ocrText,
    String targetHour,
    AiProvider provider, {
    HourlyReading? fallbackData,
  }) async {
    switch (provider) {
      case AiProvider.openai:
        return await _parseWithOpenAI(ocrText, targetHour, fallbackData: fallbackData);
      case AiProvider.anthropic:
        return await _parseWithAnthropic(ocrText, targetHour, fallbackData: fallbackData);
      case AiProvider.gemini:
        return await _parseWithGemini(ocrText, targetHour, fallbackData: fallbackData);
    }
  }

  /// Parse using OpenAI GPT
  Future<HourlyReading> _parseWithOpenAI(
    String ocrText,
    String targetHour, {
    HourlyReading? fallbackData,
  }) async {
    final prompt = _buildOpenAIPrompt(ocrText, targetHour, fallbackData);
    
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_openAiApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4-turbo-preview',
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert at extracting structured data from noisy OCR text of industrial logs. Always return valid JSON.',
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.1, // Low temperature for consistent extraction
        'max_tokens': 1000,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    final parsedData = jsonDecode(content);

    return _convertAiResponseToReading(parsedData, targetHour, ocrText, 0.85);
  }

  /// Parse using Anthropic Claude
  Future<HourlyReading> _parseWithAnthropic(
    String ocrText,
    String targetHour, {
    HourlyReading? fallbackData,
  }) async {
    final prompt = _buildAnthropicPrompt(ocrText, targetHour, fallbackData);
    
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': _anthropicApiKey,
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 1000,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Anthropic API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content = data['content'][0]['text'];
    
    // Extract JSON from Claude's response
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
    if (jsonMatch == null) {
      throw Exception('No JSON found in Claude response');
    }
    
    final parsedData = jsonDecode(jsonMatch.group(0)!);
    return _convertAiResponseToReading(parsedData, targetHour, ocrText, 0.88);
  }

  /// Parse using Google Gemini
  Future<HourlyReading> _parseWithGemini(
    String ocrText,
    String targetHour, {
    HourlyReading? fallbackData,
  }) async {
    // Placeholder for Gemini implementation
    throw UnimplementedError('Gemini parsing not yet implemented');
  }

  /// Build OpenAI prompt for structured extraction
  String _buildOpenAIPrompt(String ocrText, String targetHour, HourlyReading? fallbackData) {
    final buffer = StringBuffer();
    
    buffer.writeln('Extract methane degassing log data for hour $targetHour from this OCR text:');
    buffer.writeln('');
    buffer.writeln('OCR TEXT:');
    buffer.writeln(ocrText);
    buffer.writeln('');
    buffer.writeln('Target Hour: $targetHour');
    buffer.writeln('');
    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln('1. Focus ONLY on data for hour $targetHour');
    buffer.writeln('2. Extract these fields if present:');
    buffer.writeln('   - vaporInletFpm: Vapor inlet flow (FPM)');
    buffer.writeln('   - dilutionAirFpm: Dilution air flow (FPM)');
    buffer.writeln('   - combustionAirFpm: Combustion air flow (FPM)');
    buffer.writeln('   - exhaustTempF: Exhaust temperature (°F)');
    buffer.writeln('   - spherePressurePsi: Sphere pressure (PSI)');
    buffer.writeln('   - inletPpm: Inlet PPM concentration');
    buffer.writeln('   - outletPpm: Outlet PPM concentration');
    buffer.writeln('   - totalizerScf: Totalizer reading (SCF)');
    buffer.writeln('3. Only include fields you are confident about');
    buffer.writeln('4. Use spatial awareness - values should align with the $targetHour column');
    buffer.writeln('5. Handle OCR errors: O->0, I/l->1, etc.');
    buffer.writeln('');
    
    if (fallbackData != null) {
      buffer.writeln('REFERENCE DATA (for validation):');
      buffer.writeln('Traditional parser found: ${fallbackData.validFieldCount} fields');
      buffer.writeln('Use this to validate your extraction if needed.');
      buffer.writeln('');
    }
    
    buffer.writeln('Return JSON format:');
    buffer.writeln('''{
  "vaporInletFpm": number_or_null,
  "dilutionAirFpm": number_or_null,
  "combustionAirFpm": number_or_null,
  "exhaustTempF": number_or_null,
  "spherePressurePsi": number_or_null,
  "inletPpm": number_or_null,
  "outletPpm": number_or_null,
  "totalizerScf": number_or_null,
  "confidence": 0.0_to_1.0,
  "notes": "extraction_notes"
}''');

    return buffer.toString();
  }

  /// Build Anthropic prompt for structured extraction
  String _buildAnthropicPrompt(String ocrText, String targetHour, HourlyReading? fallbackData) {
    return '''
I need you to extract methane degassing log data from OCR text. Focus on hour $targetHour only.

OCR TEXT:
$ocrText

TASK: Extract data for hour $targetHour from the OCR text above.

The log typically has columns for different hours (00:00, 01:00, etc.) and rows for different measurements.

Extract these fields for $targetHour if present:
- Vapor inlet flow rate (FPM)
- Dilution air flow rate (FPM) 
- Combustion air flow rate (FPM)
- Exhaust temperature (°F)
- Sphere pressure (PSI)
- Inlet PPM concentration
- Outlet PPM concentration
- Totalizer reading (SCF)

Handle common OCR errors: O→0, I/l→1, etc.

Return only valid JSON:
{
  "vaporInletFpm": number_or_null,
  "dilutionAirFpm": number_or_null,
  "combustionAirFpm": number_or_null,
  "exhaustTempF": number_or_null,
  "spherePressurePsi": number_or_null,
  "inletPpm": number_or_null,
  "outletPpm": number_or_null,
  "totalizerScf": number_or_null,
  "confidence": 0.85,
  "notes": "extraction notes"
}
''';
  }

  /// Convert AI response to HourlyReading
  HourlyReading _convertAiResponseToReading(
    Map<String, dynamic> aiData,
    String targetHour,
    String rawText,
    double baseConfidence,
  ) {
    final fieldMatches = <FieldMatch>[];
    final config = LogParsingConfig.standard;

    // Convert AI fields to FieldMatch objects
    for (final entry in aiData.entries) {
      if (entry.key == 'confidence' || entry.key == 'notes') continue;
      if (entry.value == null) continue;
      
      final fieldPattern = config.fieldPatterns[entry.key];
      if (fieldPattern == null) continue;

      // Validate AI extracted value
      final validation = _validateAiValue(entry.value, fieldPattern);
      final confidence = _calculateAiConfidence(entry.value, fieldPattern, baseConfidence);

      fieldMatches.add(FieldMatch(
        name: entry.key,
        value: entry.value,
        confidence: confidence,
        rawMatch: entry.value.toString(),
        position: 0, // AI doesn't provide position
        type: fieldPattern.type,
        unit: fieldPattern.unit,
        validation: validation,
      ));
    }

    final overallConfidence = aiData['confidence']?.toDouble() ?? baseConfidence;

    return HourlyReading.fromFieldMatches(targetHour, fieldMatches, rawText);
  }

  /// Validate AI extracted value
  ValidationResult _validateAiValue(dynamic value, FieldPattern pattern) {
    final errors = <String>[];
    final warnings = <String>[];

    if (value == null) {
      errors.add('AI returned null value');
      return ValidationResult.invalid(errors);
    }

    // Range validation
    if (!pattern.isInExpectedRange(value)) {
      warnings.add('AI value outside expected range: $value');
    }

    // Type validation
    switch (pattern.type) {
      case FieldType.flowRate:
      case FieldType.temperature:
      case FieldType.totalizer:
        if (value is! int && double.tryParse(value.toString()) == null) {
          errors.add('Invalid numeric value from AI');
        }
        break;
      default:
        break;
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Calculate confidence for AI extracted value
  double _calculateAiConfidence(dynamic value, FieldPattern pattern, double baseConfidence) {
    double confidence = baseConfidence;

    // Boost confidence if value is in expected range
    if (pattern.isInExpectedRange(value)) {
      confidence += 0.1;
    } else {
      confidence -= 0.2;
    }

    // Type-specific adjustments
    if (pattern.type == FieldType.temperature && value is num && value > 1000) {
      confidence += 0.05; // Reasonable exhaust temperature
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Determine if traditional parsing was successful
  bool _isParsingSuccessful(HourlyReading result) {
    return result.overallConfidence >= _aiConfidenceThreshold && 
           result.validFieldCount >= 5;
  }

  /// Choose the best result between traditional and AI parsing
  HourlyReading _chooseBestResult(HourlyReading? traditional, HourlyReading ai) {
    if (traditional == null) return ai;

    // Score based on confidence and field count
    final traditionalScore = traditional.overallConfidence * 0.7 + 
                           (traditional.validFieldCount / 8.0) * 0.3;
    
    final aiScore = ai.overallConfidence * 0.8 + // Slight preference for AI
                   (ai.validFieldCount / 8.0) * 0.2;

    return aiScore > traditionalScore ? ai : traditional;
  }

  /// Create empty reading for error cases
  HourlyReading _createEmptyReading(String targetHour, String rawText, String reason) {
    return HourlyReading(
      inspectionTime: targetHour,
      overallConfidence: 0.0,
      fieldMatches: [],
      parsedAt: DateTime.now(),
      rawOcrText: rawText,
    );
  }
}

/// AI Provider options
enum AiProvider {
  openai,
  anthropic,
  gemini,
}

/// AI Enhancement configuration
class AiEnhancementConfig {
  final AiProvider preferredProvider;
  final double confidenceThreshold;
  final bool enableFallback;
  final int maxRetries;
  final Duration timeout;

  const AiEnhancementConfig({
    this.preferredProvider = AiProvider.openai,
    this.confidenceThreshold = 0.6,
    this.enableFallback = true,
    this.maxRetries = 2,
    this.timeout = const Duration(seconds: 30),
  });
}

/// Usage examples and integration patterns
class AiParserUsageExamples {
  
  /// Example: Basic AI-enhanced parsing
  static Future<void> basicUsage() async {
    final parser = AiEnhancedParser();
    const ocrText = 'noisy OCR text here...';
    
    final result = await parser.parseWithAiEnhancement(ocrText, '02:00');
    
    if (result.isHighQuality) {
      print('High quality extraction: ${result.validFieldCount} fields');
    } else {
      print('Lower quality extraction, manual review recommended');
    }
  }

  /// Example: With Riverpod integration
  static Future<void> riverpodIntegration(WidgetRef ref) async {
    const ocrText = 'complex OCR text...';
    const targetHour = '15:00';
    
    try {
      // Set loading state
      ref.read(ocrParsingStateProvider.notifier).startParsing(targetHour, ocrText);
      
      // Parse with AI enhancement
      final parser = AiEnhancedParser();
      final result = await parser.parseWithAiEnhancement(
        ocrText, 
        targetHour,
        preferredProvider: AiProvider.anthropic,
      );
      
      // Update state
      ref.read(ocrParsingStateProvider.notifier).completeWith(result);
      ref.read(hourlyReadingsProvider.notifier).setReading(targetHour, result);
      
      // Pre-fill form if quality is acceptable
      if (result.isAcceptable) {
        ref.read(formPreFillProvider.notifier).state = result;
      }
      
    } catch (e) {
      ref.read(ocrParsingStateProvider.notifier).failWith(e.toString());
    }
  }

  /// Example: Batch processing with AI
  static Future<Map<String, HourlyReading>> batchProcessing(
    String ocrText,
    List<String> targetHours,
  ) async {
    final parser = AiEnhancedParser();
    final results = <String, HourlyReading>{};
    
    // Process hours in parallel with rate limiting
    final futures = targetHours.map((hour) async {
      await Future.delayed(const Duration(milliseconds: 100)); // Rate limiting
      return parser.parseWithAiEnhancement(ocrText, hour);
    });
    
    final readings = await Future.wait(futures);
    
    for (int i = 0; i < targetHours.length; i++) {
      results[targetHours[i]] = readings[i];
    }
    
    return results;
  }
}