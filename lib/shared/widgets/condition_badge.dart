import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../models/product.dart';

class ConditionBadge extends StatelessWidget {
  final ProductCondition condition;
  /// Use [compact] for small pill on the card image overlay.
  final bool compact;

  const ConditionBadge({
    super.key,
    required this.condition,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isNew = condition == ProductCondition.newProduct;
    final label = isNew ? l10n.conditionNew : l10n.conditionRefurbished;
    final bg = isNew
        ? AppColors.primary.withValues(alpha: 0.15)
        : const Color(0xFF7C5CBF).withValues(alpha: 0.13);
    final textColor =
        isNew ? AppColors.primaryDark : const Color(0xFF6B46C1);
    final icon = isNew ? Icons.fiber_new_rounded : Icons.recycling_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 12, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
