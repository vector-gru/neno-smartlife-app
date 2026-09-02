import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/category_service.dart';
import '../../core/state/app_state.dart';
import '../../shared/models/admin_category.dart';
import 'admin_edit_category_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin – Manage Categories Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminManageCategoriesScreen extends StatelessWidget {
  const AdminManageCategoriesScreen({super.key});

  void _openEdit(BuildContext context, AdminCategory cat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminEditCategoryScreen(
          category: cat,
          isNew: false,
          onSave: (updated) => CategoryService.instance.updateCategory(updated),
          onDelete: (id) => CategoryService.instance.deleteCategory(id),
        ),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    final newCat = AdminCategory(
      id: '',
      name: '',
      description: '',
      icon: Icons.category_rounded,
      productCount: 0,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminEditCategoryScreen(
          category: newCat,
          isNew: true,
          onSave: (created) => CategoryService.instance.createCategory(created),
          onDelete: (_) async {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final categories = context.appState.categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Categories',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Organize and structure your marketplace catalog.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      body: categories.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category_outlined,
                      size: 52, color: AppColors.border),
                  const SizedBox(height: 12),
                  Text(
                    'No categories yet',
                    style: GoogleFonts.poppins(
                        fontSize: 15, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap + to add your first category.',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _CategoryCard(
                category: categories[i],
                onTap: () => _openEdit(context, categories[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Card
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final AdminCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Live product count from Firestore catalogue
    final liveCount = context.appState.products
        .where((p) => p.category == category.name)
        .length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: SizedBox(
                width: 72,
                height: 72,
                child: category.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: category.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _iconFallback(),
                        errorWidget: (_, __, ___) => _iconFallback(),
                      )
                    : _iconFallback(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$liveCount product${liveCount == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconFallback() => Container(
        color: AppColors.primary.withValues(alpha: 0.08),
        child: Center(
          child: Icon(category.icon, color: AppColors.primary, size: 28),
        ),
      );
}
