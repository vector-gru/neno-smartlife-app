import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';

/// Renders a single product image URL that may be either a remote https URL
/// or a local file path (e.g. picked from camera / gallery before upload).
///
/// Drop-in replacement for [CachedNetworkImage] in all customer and admin
/// product image slots.
class ProductImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Shown while a remote image is loading. Defaults to a shimmer placeholder.
  final Widget Function(BuildContext)? placeholder;

  /// Shown when the image cannot be loaded. Defaults to a grey icon container.
  final Widget? errorWidget;

  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  bool get _isLocal => !url.startsWith('http');

  Widget _defaultPlaceholder(BuildContext context) =>
      placeholder?.call(context) ??
      Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(color: Colors.white),
      );

  Widget get _defaultError =>
      errorWidget ??
      Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 32,
            color: AppColors.textMuted,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _defaultError;

    if (_isLocal) {
      return Image.file(
        File(url),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _defaultError,
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (ctx, _) => _defaultPlaceholder(ctx),
      errorWidget: (_, __, ___) => _defaultError,
    );
  }
}
