import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class ProductBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const ProductBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    final bg = color ??
        (label == 'NEW'
            ? AppColors.primary
            : label == 'HOT'
                ? AppColors.error
                : label == 'SALE'
                    ? AppColors.warning
                    : AppColors.primary);
    final textColor =
        label == 'NEW' ? AppColors.textOnPrimary : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
