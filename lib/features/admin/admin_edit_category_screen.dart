import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/models/admin_category.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin – Add / Edit Category Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminEditCategoryScreen extends StatefulWidget {
  final AdminCategory category;
  final bool isNew;
  final void Function(AdminCategory) onSave;
  final void Function(String) onDelete;

  const AdminEditCategoryScreen({
    super.key,
    required this.category,
    required this.onSave,
    required this.onDelete,
    this.isNew = false,
  });

  @override
  State<AdminEditCategoryScreen> createState() =>
      _AdminEditCategoryScreenState();
}

class _AdminEditCategoryScreenState extends State<AdminEditCategoryScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String? _thumbnailUrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category.name);
    _descCtrl = TextEditingController(text: widget.category.description);
    _thumbnailUrl = widget.category.thumbnailUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = AdminCategory(
      id: widget.category.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      icon: widget.category.icon,
      productCount: widget.category.productCount,
      thumbnailUrl: _thumbnailUrl,
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Category',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "${_nameCtrl.text}"? Products in this category will be uncategorised.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDelete(widget.category.id);
              Navigator.of(context).pop();
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isNew ? 'Add Category' : 'Edit Category',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Thumbnail upload zone ────────────────────────────────────
          _buildThumbnailZone(),
          const SizedBox(height: 16),

          // ── Fields card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Category Name'),
                _textField(_nameCtrl,
                    hint: 'e.g. Smart Watches'),
                const SizedBox(height: 16),
                _fieldLabel('Description (Optional)'),
                _textField(
                  _descCtrl,
                  hint:
                      'e.g. Premium wearable technology and fitness trackers.',
                  maxLines: 4,
                ),
              ],
            ),
          ),

          // ── Spacer so buttons don't crowd content ────────────────────
          const SizedBox(height: 48),
        ],
      ),

      // ── Bottom action buttons ────────────────────────────────────────
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  // ── Thumbnail zone ─────────────────────────────────────────────────────────
  Widget _buildThumbnailZone() {
    return GestureDetector(
      onTap: () {}, // would open image picker
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _thumbnailUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const _ThumbnailPlaceholder(),
                    errorWidget: (_, __, ___) =>
                        const _ThumbnailPlaceholder(),
                  ),
                  // Overlay with replace hint
                  Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            color: Colors.white, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          'Click to replace image',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        Text(
                          'SVG, PNG, JPG or GIF (max. 800×400px)',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const _ThumbnailPlaceholder(),
      ),
    );
  }

  // ── Bottom action buttons ──────────────────────────────────────────────────
  Widget _buildBottomActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Save
            GestureDetector(
              onTap: _save,
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded,
                        color: AppColors.textOnPrimary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Save Category',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!widget.isNew) ...[
              const SizedBox(height: 10),
              // Delete
              GestureDetector(
                onTap: _confirmDelete,
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Delete Category',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _textField(TextEditingController ctrl,
      {String hint = '', int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
          fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: const Color(0xFFF4F4F4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thumbnail Placeholder (no image set)
// ─────────────────────────────────────────────────────────────────────────────

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_outlined,
            color: AppColors.textMuted, size: 30),
        const SizedBox(height: 8),
        Text(
          'Click to replace image',
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary),
        ),
        Text(
          'SVG, PNG, JPG or GIF (max. 800×400px)',
          style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
