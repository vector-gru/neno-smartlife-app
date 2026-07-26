import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class StockChip extends StatelessWidget {
  final String stockStatus;

  const StockChip({super.key, required this.stockStatus});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    late Color bg;
    late Color textColor;
    late String label;

    switch (stockStatus) {
      case 'limited':
        bg = AppColors.stockLimited.withValues(alpha: 0.12);
        textColor = AppColors.stockLimited;
        label = l10n.limitedStock;
        break;
      case 'out_of_stock':
        bg = AppColors.stockOut.withValues(alpha: 0.12);
        textColor = AppColors.stockOut;
        label = l10n.outOfStock;
        break;
      default:
        bg = AppColors.stockIn.withValues(alpha: 0.10);
        textColor = AppColors.stockIn;
        label = l10n.inStock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
