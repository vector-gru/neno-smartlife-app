import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

/// A pill-shaped search field that matches the home screen style.
///
/// Usage:
/// ```dart
/// AppSearchBar(
///   controller: _searchCtrl,
///   hintText: 'Search products…',
///   onChanged: (v) => setState(() => _query = v),
/// )
/// ```
///
/// Wrap in a [Container]/[ColoredBox] with the desired background colour
/// if you need the surrounding strip to be white (e.g. inside an app bar
/// area). The widget itself only controls its own padding + field styling.
class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  /// Padding around the field. Defaults to match the home screen style.
  final EdgeInsets padding;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.focusNode,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: controller.value.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF2F2F2),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
