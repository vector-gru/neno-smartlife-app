import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/product_service.dart';
import '../../core/state/app_state.dart';
import '../../shared/models/product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin – Add / Edit Product Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminEditProductScreen extends StatefulWidget {
  final Product product;
  final bool isNew;
  final void Function(Product) onSave;
  final void Function(String) onDelete;

  const AdminEditProductScreen({
    super.key,
    required this.product,
    required this.onSave,
    required this.onDelete,
    this.isNew = false,
  });

  @override
  State<AdminEditProductScreen> createState() => _AdminEditProductScreenState();
}

class _AdminEditProductScreenState extends State<AdminEditProductScreen> {
  // Categories are loaded from Firestore via AppStateProvider.
  List<String> get _categories =>
      context.appState.categories.map((c) => c.name).toList();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _originalPriceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _qtyCtrl;
  late String _category;
  late bool _featured;
  late List<String> _imageUrls;
  late List<MapEntry<String, String>> _specs;
  late String _stockStatus;
  late ProductCondition _condition;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p.name);
    _priceCtrl = TextEditingController(
        text: p.price > 0 ? p.price.toStringAsFixed(0) : '');
    _originalPriceCtrl = TextEditingController(
        text: p.originalPrice != null && p.originalPrice! > 0
            ? p.originalPrice!.toStringAsFixed(0)
            : '');
    _descCtrl = TextEditingController(text: p.description);
    _qtyCtrl = TextEditingController(
        text: p.quantity > 0 ? p.quantity.toString() : '');
    _category = p.category.isEmpty ? '' : p.category;
    _featured = p.featured || p.badge == 'HOT' || p.badge == 'NEW';
    _imageUrls = List.from(p.imageUrls);
    // Exclude 'Quantity' in case it was previously stored in specs (migration safety)
    _specs =
        p.specifications.entries.where((e) => e.key != 'Quantity').toList();
    _stockStatus = p.stockStatus.isEmpty ? 'in_stock' : p.stockStatus;
    _condition = p.condition;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _originalPriceCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  static const _maxImages = 8;
  final _picker = ImagePicker();
  bool _isSaving = false;

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
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
                'Add Product Image',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_camera_outlined,
                      color: AppColors.primary),
                ),
                title: Text('Take a Photo',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Use the camera',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textMuted)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImages(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
                ),
                title: Text('Choose from Gallery',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Pick one or multiple images',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textMuted)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImages(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      final remaining = _maxImages - _imageUrls.length;
      if (remaining <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum $_maxImages images reached.',
                style: GoogleFonts.poppins(fontSize: 13)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (source == ImageSource.camera) {
        final photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (photo != null) {
          setState(() => _imageUrls.add(photo.path));
        }
      } else {
        final photos = await _picker.pickMultiImage(imageQuality: 85);
        if (photos.isNotEmpty) {
          final toAdd = photos.take(remaining).map((x) => x.path).toList();
          setState(() => _imageUrls.addAll(toAdd));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e',
                style: GoogleFonts.poppins(fontSize: 13)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    // Basic validation
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product name is required.',
              style: GoogleFonts.poppins(fontSize: 13)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_category.isEmpty || !_categories.contains(_category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _categories.isEmpty
                ? 'Please add a category first before saving a product.'
                : 'Please select a category.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Upload any locally-picked images to Cloudinary.
      //    Already-remote URLs are passed through unchanged.
      final uploadedUrls =
          await CloudinaryService.instance.uploadImages(_imageUrls);

      // 2. Build the product with the final URLs.
      final product = Product(
        id: widget.product.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        originalPrice: double.tryParse(_originalPriceCtrl.text.trim()),
        category: _category,
        imageUrls: uploadedUrls,
        badge: _featured ? 'HOT' : '',
        featured: _featured,
        stockStatus: _stockStatus,
        quantity: int.tryParse(_qtyCtrl.text.trim()) ?? 0,
        specifications: Map.fromEntries(_specs),
        condition: _condition,
      );

      // 3. Write to Firestore.
      if (widget.isNew) {
        await ProductService.instance.createProduct(product);
      } else {
        await ProductService.instance.updateProduct(product);
      }

      // 4. Also call the in-memory callback so the UI reflects the change
      //    immediately (Firestore stream will confirm shortly after).
      widget.onSave(product);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e',
                style: GoogleFonts.poppins(fontSize: 13)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Product',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently remove "${_nameCtrl.text}". Continue?',
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
              try {
                await ProductService.instance.deleteProduct(widget.product.id);
                widget.onDelete(widget.product.id);
              } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _SectionCard(children: [
            _sectionTitle('Basic Information'),
            const SizedBox(height: 16),
            _fieldLabel('Product Name'),
            _textField(_nameCtrl, hint: 'e.g. Samsung Galaxy S24 Ultra'),
            const SizedBox(height: 14),
            _fieldLabel('Category'),
            _categoryDropdown(),
            const SizedBox(height: 14),
            _fieldLabel('Price (FCFA)'),
            _textField(_priceCtrl,
                hint: '850000',
                keyboardType: TextInputType.number,
                prefix: 'F '),
            const SizedBox(height: 14),
            _fieldLabel('Original Price — before discount (FCFA)'),
            _textField(_originalPriceCtrl,
                hint: 'Leave empty for no discount',
                keyboardType: TextInputType.number,
                prefix: 'F '),
            // ── Live discount preview ──────────────────────────────────────
            _DiscountPreview(
              priceCtrl: _priceCtrl,
              originalPriceCtrl: _originalPriceCtrl,
            ),
            const SizedBox(height: 14),
            _fieldLabel('Description'),
            _textField(_descCtrl, hint: 'Product description…', maxLines: 4),
          ]),
          const SizedBox(height: 16),
          _buildImagesSection(),
          const SizedBox(height: 16),
          _buildInventorySection(),
          const SizedBox(height: 16),
          _buildSpecificationsSection(),
          const SizedBox(height: 24),
          if (!widget.isNew) _buildDeleteButton(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF5F5F5),
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: const Icon(Icons.arrow_back_rounded,
            color: AppColors.textPrimary, size: 22),
      ),
      title: Text(
        widget.isNew ? 'Add Product' : 'Edit Product',
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: _isSaving ? null : _save,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: _isSaving
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.textOnPrimary),
                      ),
                    )
                  : Text(
                      'Save Product',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    final uploadedCount = _imageUrls.length;

    return _SectionCard(children: [
      Row(
        children: [
          _sectionTitle('Product Images'),
          const Spacer(),
          Text(
            '$uploadedCount / $_maxImages Uploaded',
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted),
          ),
        ],
      ),
      const SizedBox(height: 14),
      // Upload tap zone
      GestureDetector(
        onTap: _imageUrls.length < _maxImages ? _showImageSourceSheet : null,
        child: Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _imageUrls.length < _maxImages
                  ? AppColors.border
                  : AppColors.border.withValues(alpha: 0.4),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: _imageUrls.length < _maxImages
                    ? AppColors.textMuted
                    : AppColors.border,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                _imageUrls.length < _maxImages
                    ? 'Tap to add from camera or gallery'
                    : 'Maximum images reached',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _imageUrls.length < _maxImages
                        ? AppColors.textSecondary
                        : AppColors.textMuted),
              ),
              if (_imageUrls.isEmpty)
                Text(
                  'First image becomes the primary',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ),
      if (_imageUrls.isNotEmpty) ...[
        const SizedBox(height: 12),
        _buildImageGrid(),
      ],
    ]);
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _imageUrls.length,
      itemBuilder: (context, index) {
        final url = _imageUrls[index];
        final isLocal = !url.startsWith('http');
        final isMain = index == 0;

        Widget imageWidget = isLocal
            ? Image.file(
                File(url),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF2F2F2),
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.border),
                ),
              )
            : CachedNetworkImage(
                imageUrl: url,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: const Color(0xFFF2F2F2)),
                errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFF2F2F2),
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.border)),
              );

        return GestureDetector(
          onTap: () => _showImageOptionsSheet(index),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageWidget,
              ),
              // "NEW" badge for locally picked images not yet uploaded
              if (isLocal)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('NEW',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
              if (isMain && !isLocal)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('MAIN',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textOnPrimary)),
                  ),
                ),
              if (isMain && isLocal)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text('MAIN',
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textOnPrimary)),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text('NEW',
                            style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _imageUrls.removeAt(index)),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xCC000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImageOptionsSheet(int index) {
    final isMain = index == 0;
    showModalBottomSheet<void>(
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
                isMain ? 'Main Image' : 'Image Options',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (!isMain)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: AppColors.primary),
                  ),
                  title: Text('Set as Main Image',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('Move to first position',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textMuted)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      final img = _imageUrls.removeAt(index);
                      _imageUrls.insert(0, img);
                    });
                  },
                ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                ),
                title: Text('Remove Image',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _imageUrls.removeAt(index));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Inventory section ──────────────────────────────────────────────────────
  Widget _buildInventorySection() {
    return _SectionCard(children: [
      _sectionTitle('Inventory'),
      const SizedBox(height: 16),
      _fieldLabel('Quantity Available'),
      SizedBox(
        width: 120,
        child:
            _textField(_qtyCtrl, hint: '0', keyboardType: TextInputType.number),
      ),
      const SizedBox(height: 20),
      _fieldLabel('Stock Status'),
      _StockStatusSelector(
        value: _stockStatus,
        onChanged: (v) => setState(() => _stockStatus = v),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Featured Product',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Show on store homepage',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _featured,
            onChanged: (v) => setState(() => _featured = v),
            activeThumbColor: AppColors.textOnPrimary,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
      const SizedBox(height: 20),
      _fieldLabel('Product Condition'),
      const SizedBox(height: 8),
      _ConditionSelector(
        value: _condition,
        onChanged: (v) => setState(() => _condition = v),
      ),
    ]);
  }

  // ── Specifications section ─────────────────────────────────────────────────
  Widget _buildSpecificationsSection() {
    return _SectionCard(children: [
      Row(
        children: [
          _sectionTitle('Specifications'),
          const Spacer(),
          if (_category.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_category}s Preset',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnPrimary),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      ..._specs.asMap().entries.map((e) {
        final i = e.key;
        final spec = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SpecRow(
            label: spec.key,
            value: spec.value,
            onChanged: (newVal) {
              setState(() {
                _specs[i] = MapEntry(spec.key, newVal);
              });
            },
            onRemove: () => setState(() => _specs.removeAt(i)),
          ),
        );
      }),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: _addCustomField,
        child: Container(
          height: 42,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1.2),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '+ Add Custom Field',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  void _addCustomField() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final keyCtrl = TextEditingController();
        final valCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Custom Field',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _fieldLabel('Field Name'),
              TextField(
                controller: keyCtrl,
                autofocus: true,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration('e.g. Warranty'),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Value'),
              TextField(
                controller: valCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration('e.g. 2 Years'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final k = keyCtrl.text.trim();
                  final v = valCtrl.text.trim();
                  if (k.isNotEmpty) {
                    setState(() => _specs.add(MapEntry(k, v)));
                  }
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Add Field',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Delete button ──────────────────────────────────────────────────────────
  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _confirmDelete,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text(
              'Delete Product',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _textField(
    TextEditingController ctrl, {
    String hint = '',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: _inputDecoration(hint, prefix: prefix),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
      prefixText: prefix,
      prefixStyle:
          GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
      filled: true,
      fillColor: const Color(0xFFF4F4F4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _categoryDropdown() {
    final cats = _categories;
    final noneYet = cats.isEmpty;

    // If current _category is no longer in the list (e.g. category was deleted),
    // reset it so the dropdown doesn't show an invalid value.
    if (!noneYet && _category.isNotEmpty && !cats.contains(_category)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _category = '');
      });
    }

    if (noneYet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No categories yet — add one in Manage Categories first.',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    // Ensure the dropdown value is always valid
    final effectiveValue = cats.contains(_category) ? _category : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          hint: Text('Select a category',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textMuted)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style:
              GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
          onChanged: (v) {
            if (v != null) setState(() => _category = v);
          },
          items: cats
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Condition Selector
// ─────────────────────────────────────────────────────────────────────────────

class _ConditionSelector extends StatelessWidget {
  final ProductCondition value;
  final ValueChanged<ProductCondition> onChanged;

  const _ConditionSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ConditionOption(
            label: 'New',
            icon: Icons.fiber_new_rounded,
            selected: value == ProductCondition.newProduct,
            onTap: () => onChanged(ProductCondition.newProduct),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ConditionOption(
            label: 'Fairly Used',
            icon: Icons.recycling_rounded,
            selected: value == ProductCondition.refurbished,
            onTap: () => onChanged(ProductCondition.refurbished),
          ),
        ),
      ],
    );
  }
}

class _ConditionOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ConditionOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: AppColors.textOnPrimary)
                  : null,
            ),
            const SizedBox(width: 10),
            Icon(icon,
                size: 16,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Discount Preview
// ─────────────────────────────────────────────────────────────────────────────

class _DiscountPreview extends StatefulWidget {
  final TextEditingController priceCtrl;
  final TextEditingController originalPriceCtrl;

  const _DiscountPreview({
    required this.priceCtrl,
    required this.originalPriceCtrl,
  });

  @override
  State<_DiscountPreview> createState() => _DiscountPreviewState();
}

class _DiscountPreviewState extends State<_DiscountPreview> {
  @override
  void initState() {
    super.initState();
    widget.priceCtrl.addListener(_rebuild);
    widget.originalPriceCtrl.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.priceCtrl.removeListener(_rebuild);
    widget.originalPriceCtrl.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(widget.priceCtrl.text.trim()) ?? 0;
    final original = double.tryParse(widget.originalPriceCtrl.text.trim()) ?? 0;
    final hasDiscount = original > price && price > 0 && original > 0;

    if (!hasDiscount) return const SizedBox.shrink();

    final pct = (((original - price) / original) * 100).round();
    final fmtPrice = _fmt(price);
    final fmtOriginal = _fmt(original);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_rounded,
                size: 16, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              'Customers save ',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              '$pct%',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success),
            ),
            const Spacer(),
            // Strikethrough original
            Text(
              'F $fmtOriginal',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textMuted,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 6),
            // Sale price
            Text(
              'F $fmtPrice',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Section Card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock Status Selector
// ─────────────────────────────────────────────────────────────────────────────

class _StockStatusSelector extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const _StockStatusSelector({
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    (
      value: 'in_stock',
      label: 'In Stock',
      color: AppColors.success,
      bg: Color(0xFFECFDF5)
    ),
    (
      value: 'limited',
      label: 'Low Stock',
      color: AppColors.warning,
      bg: Color(0xFFFEF9EC)
    ),
    (
      value: 'out_of_stock',
      label: 'Out of Stock',
      color: AppColors.error,
      bg: Color(0xFFFEF2F2)
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final selected = value == opt.value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? opt.bg : const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? opt.color.withValues(alpha: 0.5)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? opt.color : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spec Row (label + editable value)
// ─────────────────────────────────────────────────────────────────────────────

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  final void Function(String) onChanged;
  final VoidCallback onRemove;

  const _SpecRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.remove_circle_outline_rounded,
                  size: 16, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          style:
              GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter value',
            hintStyle:
                GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
            filled: true,
            fillColor: const Color(0xFFF4F4F4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
