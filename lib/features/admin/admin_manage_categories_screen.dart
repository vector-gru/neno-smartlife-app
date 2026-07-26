import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/data/mock_categories.dart';
import '../../shared/models/admin_category.dart';
import 'admin_edit_category_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin – Manage Categories Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminManageCategoriesScreen extends StatefulWidget {
  const AdminManageCategoriesScreen({super.key});

  @override
  State<AdminManageCategoriesScreen> createState() =>
      _AdminManageCategoriesScreenState();
}

class _AdminManageCategoriesScreenState
    extends State<AdminManageCategoriesScreen> {
  late final List<AdminCategory> _categories =
      List.from(MockCategories.all);

  void _openEdit(AdminCategory cat) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminEditCategoryScreen(
          category: cat,
          isNew: false,
          onSave: (updated) => setState(() {
            final i = _categories.indexWhere((c) => c.id == updated.id);
            if (i >= 0) _categories[i] = updated;
          }),
          onDelete: (id) => setState(
              () => _categories.removeWhere((c) => c.id == id)),
        ),
      ),
    );
  }

  void _openAdd() async {
    final newCat = AdminCategory(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: '',
      description: '',
      icon: Icons.category_rounded,
      productCount: 0,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminEditCategoryScreen(
          category: newCat,
          isNew: true,
          onSave: (created) =>
              setState(() => _categories.add(created)),
          onDelete: (_) {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
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
      body: _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category_outlined,
                      size: 52, color: AppColors.border),
                  const SizedBox(height: 12),
                  Text('No categories yet',
                      style: GoogleFonts.poppins(
                          fontSize: 15, color: AppColors.textMuted)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _CategoryCard(
                category: _categories[i],
                onTap: () => _openEdit(_categories[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail / icon area
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14)),
              child: SizedBox(
                width: 72,
                height: 72,
                child: category.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: category.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            _iconFallback(category.icon),
                        errorWidget: (_, __, ___) =>
                            _iconFallback(category.icon),
                      )
                    : _iconFallback(category.icon),
              ),
            ),
            const SizedBox(width: 14),
            // Text
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
                    '${category.productCount} Products',
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

  Widget _iconFallback(IconData icon) => Container(
        color: AppColors.primary.withValues(alpha: 0.08),
        child: Center(
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
      );
}
