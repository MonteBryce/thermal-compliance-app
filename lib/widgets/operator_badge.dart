/// Operator Badge Widget (Discord-style avatars)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OperatorBadge extends StatelessWidget {
  final String initials;
  final Color? backgroundColor;
  final double size;
  final bool isOnline;

  const OperatorBadge({
    super.key,
    required this.initials,
    this.backgroundColor,
    this.size = 32,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? _generateColor(initials);
    
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(
              color: const Color(0xFF2A2A2A),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              initials.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        // Online indicator
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(size * 0.125),
                border: Border.all(
                  color: const Color(0xFF1E1E1E),
                  width: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _generateColor(String text) {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF84CC16), // Lime
    ];
    
    final hash = text.hashCode;
    return colors[hash.abs() % colors.length];
  }
}

class OperatorPillGroup extends StatelessWidget {
  final List<String> operators;
  final double badgeSize;
  final int maxVisible;

  const OperatorPillGroup({
    super.key,
    required this.operators,
    this.badgeSize = 28,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    final visibleOperators = operators.take(maxVisible).toList();
    final hiddenCount = operators.length - maxVisible;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleOperators.map((operator) => Padding(
          padding: const EdgeInsets.only(right: 4),
          child: OperatorBadge(
            initials: _getInitials(operator),
            size: badgeSize,
          ),
        )),
        
        if (hiddenCount > 0)
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(badgeSize / 2),
              border: Border.all(
                color: const Color(0xFF2A2A2A),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '+$hiddenCount',
                style: GoogleFonts.inter(
                  fontSize: badgeSize * 0.35,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}';
    } else if (words.isNotEmpty) {
      return words[0].length >= 2 ? words[0].substring(0, 2) : words[0][0];
    }
    return '??';
  }
}
