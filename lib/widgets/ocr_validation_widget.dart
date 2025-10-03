import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/enhanced_ocr_service.dart';
import '../services/enhanced_ocr_service_backup.dart';
import '../services/anti_hallucination_parser.dart';
import '../services/ocr_validation_service.dart' as validation;
import '../providers/enhanced_ocr_providers.dart';

/// Widget to display OCR validation results and anti-hallucination information
class OcrValidationWidget extends ConsumerWidget {
  final EnhancedOcrResult? ocrResult;
  final VoidCallback? onManualReview;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const OcrValidationWidget({
    super.key,
    this.ocrResult,
    this.onManualReview,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ocrResult == null) {
      return const SizedBox.shrink();
    }

    final validationResult = ocrResult!.validationResult;
    final antiHallucinationResult = ocrResult!.antiHallucinationResult;
    final stats = ref.watch(ocrProcessingStatsProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, validationResult),
            const SizedBox(height: 16),

            // Confidence and Statistics
            _buildConfidenceSection(context, ocrResult!, stats),
            const SizedBox(height: 16),

            // Validation Results
            _buildValidationSection(context, validationResult),
            const SizedBox(height: 16),

            // Hallucination Detection
            _buildHallucinationSection(context, antiHallucinationResult),
            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(context, validationResult),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, validation.ValidationResult validationResult) {
    final isValid = validationResult.isValid;
    final requiresReview = validationResult.requiresManualReview;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!isValid) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Validation Failed';
    } else if (requiresReview) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Manual Review Required';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Validation Passed';
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 24),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceSection(BuildContext context,
      EnhancedOcrResult ocrResult, Map<String, dynamic>? stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Processing Statistics',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Overall Confidence',
                '${(ocrResult.confidence * 100).toStringAsFixed(1)}%',
                _getConfidenceColor(ocrResult.confidence),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Fields Extracted',
                '${ocrResult.extractedFields.length}',
                Colors.blue,
              ),
            ),
          ],
        ),
        if (stats != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Hallucination Flags',
                  '${stats['hallucinationFlagsCount'] ?? 0}',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Validation Errors',
                  '${stats['validationErrorsCount'] ?? 0}',
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValidationSection(
      BuildContext context, validation.ValidationResult validationResult) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Validation Results',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Validation checks
        if (validationResult.checks.isNotEmpty) ...[
          ...validationResult.checks
              .map((check) => _buildValidationCheck(check)),
          const SizedBox(height: 8),
        ],

        // Errors
        if (validationResult.errors.isNotEmpty) ...[
          _buildErrorList('Errors', validationResult.errors, Colors.red),
          const SizedBox(height: 8),
        ],

        // Warnings
        if (validationResult.warnings.isNotEmpty) ...[
          _buildErrorList('Warnings', validationResult.warnings, Colors.orange),
        ],
      ],
    );
  }

  Widget _buildValidationCheck(validation.ValidationCheck check) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            check.isValid ? Icons.check_circle : Icons.cancel,
            color: check.isValid ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              check.name,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: check.isValid ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorList(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: color)),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildHallucinationSection(
      BuildContext context, AntiHallucinationResult antiHallucinationResult) {
    if (antiHallucinationResult.hallucinationFlags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anti-Hallucination Detection',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...antiHallucinationResult.hallucinationFlags
            .map((flag) => _buildHallucinationFlag(flag)),
      ],
    );
  }

  Widget _buildHallucinationFlag(HallucinationFlag flag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Text(
                flag.type,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            flag.description,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          ...[
          const SizedBox(height: 4),
          Text(
            'Confidence: ${(flag.confidence! * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, validation.ValidationResult validationResult) {
    final isValid = validationResult.isValid;
    final requiresReview = validationResult.requiresManualReview;

    return Row(
      children: [
        if (requiresReview && onManualReview != null) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onManualReview,
              icon: const Icon(Icons.visibility),
              label: const Text('Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (isValid && onAccept != null) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (onReject != null) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
