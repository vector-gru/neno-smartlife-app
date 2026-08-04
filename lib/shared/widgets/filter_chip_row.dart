import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// A horizontally scrollable row of pill-style filter chips.
///
/// Generic over [T] so it works for any tab value type — strings,
/// enums, nulls, etc.
///
/// Example:
/// ```dart
/// FilterChipRow<String?>(
///   items: const {'All': null, 'New': 'new', 'Done': 'done'},
///   selected: _filter,
///   onSelected: (v) => setState(() => _filter = v),
/// )
/// ```
class FilterChipRow<T> extends StatelessWidget {
  /// Ordered map of label → value. Insertion order is preserved.
  final Map<String, T> items;

  /// Currently selected value.
  final T selected;

  /// Called when the user taps a chip.
  final ValueChanged<T> onSelected;

  /// Horizontal padding applied to the scroll view. Defaults to 16.
  final double horizontalPadding;

  /// Top padding. Defaults to 10.
  final double paddingTop;

  /// Bottom padding. Defaults to 12.
  final double paddingBottom;

  /// Background color of the container. Defaults to [Colors.white].
  final Color? backgroundColor;

  const FilterChipRow({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.horizontalPadding = 16,
    this.paddingTop = 10,
    this.paddingBottom = 12,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.white,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        paddingTop,
        horizontalPadding,
        paddingBottom,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.entries.map((e) {
            final isSelected = selected == e.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip<T>(
                label: e.key,
                value: e.value,
                isSelected: isSelected,
                onTap: () => onSelected(e.value),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FilterChip<T> extends StatelessWidget {
  final String label;
  final T value;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.textOnPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
