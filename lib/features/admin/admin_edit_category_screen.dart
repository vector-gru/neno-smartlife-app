import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/cloudinary_service.dart';
import '../../shared/models/admin_category.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin – Add / Edit Category Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminEditCategoryScreen extends StatefulWidget {
  final AdminCategory category;
  final bool isNew;
  final Future<void> Function(AdminCategory) onSave;
  final Future<void> Function(String) onDelete;

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

  /// Remote URL already saved in Firestore (null = no image yet).
  late String? _thumbnailUrl;

  /// Local file picked by the user but not yet uploaded.
  File? _localImage;

  bool _isSaving = false;
  bool _isPickingImage = false;

  final _picker = ImagePicker();

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

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    // Show source selection sheet
    final source = await _showSourceSheet();
    if (source == null) return;

    setState(() => _isPickingImage = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _localImage = File(picked.path);
          // Clear any existing remote URL — the local file takes priority
          _thumbnailUrl = null;
        });
      }
    } catch (e) {
      if (mounted) _showError('Could not pick image: $e');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Category Image',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: _iconTile(Icons.photo_camera_outlined),
                title: Text('Take a Photo',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Use the camera',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textMuted)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: _iconTile(Icons.photo_library_outlined),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Pick an image',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textMuted)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              if (_thumbnailUrl != null || _localImage != null)
                ListTile(
                  leading: _iconTile(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  title: Text('Remove Image',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error)),
                  onTap: () {
                    setState(() {
                      _thumbnailUrl = null;
                      _localImage = null;
                    });
                    Navigator.of(ctx).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconTile(IconData icon, {Color color = AppColors.primary}) =>
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      );

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Category name is required.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? finalUrl = _thumbnailUrl;

      // Upload local image to Cloudinary if one was picked
      if (_localImage != null) {
        finalUrl = await CloudinaryService.instance.uploadImage(_localImage!);
      }

      final updated = AdminCategory(
        id: widget.category.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        icon: widget.category.icon,
        productCount: widget.category.productCount,
        thumbnailUrl: finalUrl,
      );

      await widget.onSave(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showError('Save failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Category',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "${_nameCtrl.text}"? Products in this category will be uncategorised.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.onDelete(widget.category.id);
              if (mounted) Navigator.of(context).pop();
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _buildThumbnailZone(),
            const SizedBox(height: 16),
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
                  _textField(_nameCtrl, hint: 'e.g. Smart Watches'),
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
            const SizedBox(height: 48),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  // ── Thumbnail zone ─────────────────────────────────────────────────────────

  Widget _buildThumbnailZone() {
    final hasLocal = _localImage != null;
    final hasRemote = _thumbnailUrl != null;
    final hasImage = hasLocal || hasRemote;

    return GestureDetector(
      onTap: _isSaving ? null : _pickImage,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // Image preview
                  hasLocal
                      ? Image.file(_localImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _ThumbnailPlaceholder())
                      : CachedNetworkImage(
                          imageUrl: _thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const _ThumbnailPlaceholder(),
                          errorWidget: (_, __, ___) =>
                              const _ThumbnailPlaceholder(),
                        ),
                  // Dark overlay
                  Container(color: Colors.black.withValues(alpha: 0.32)),
                  // Overlay label
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined,
                            color: Colors.white, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          hasLocal ? 'New image selected' : 'Tap to change',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        if (hasLocal)
                          Text(
                            'Will be uploaded on save',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                  // "NEW" badge for locally picked images
                  if (hasLocal)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('NEW',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                ],
              )
            : _isPickingImage
                ? const Center(child: CircularProgressIndicator())
                : const _ThumbnailPlaceholder(),
      ),
    );
  }

  // ── Bottom actions ─────────────────────────────────────────────────────────

  Widget _buildBottomActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Save button
            GestureDetector(
              onTap: _isSaving ? null : _save,
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _isSaving
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.textOnPrimary),
                        ),
                      )
                    : Row(
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
              GestureDetector(
                onTap: _isSaving ? null : _confirmDelete,
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
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Thumbnail Placeholder ────────────────────────────────────────────────────

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
          'Tap to add a cover image',
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary),
        ),
        Text(
          'PNG, JPG or GIF — optional',
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
