import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/state/app_state.dart';
import '../../routes/app_router.dart';
import '../../shared/models/product.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final l10n = context.l10n;
    final state = context.appState;
    final favourites = state.favourites;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: _buildAppBar(context, l10n, state),
      body: favourites.isEmpty
          ? _buildEmpty(context, l10n)
          : _buildGrid(context, l10n, state, favourites),
    );
  }

  // ─── App bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    AppStateProviderState state,
  ) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.border,
      leadingWidth: 48,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      'N',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      titleSpacing: 6,
      title: Text(
        l10n.appName,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        // My Wishlist label
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            l10n.myWishlist,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Cart icon
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.textPrimary, size: 24),
              onPressed: () => AppRouter.goToCart(context),
            ),
            if (state.cartCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 72,
              color: AppColors.textMuted.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.favEmpty,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.favEmptySub,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  l10n.shopNow,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Product grid ───────────────────────────────────────────────────────────
  Widget _buildGrid(
    BuildContext context,
    AppLocalizations l10n,
    AppStateProviderState state,
    List<Product> favourites,
  ) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.savedItems,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${favourites.length} ${l10n.items}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _FavouriteCard(
                product: favourites[index],
                l10n: l10n,
                state: state,
              ),
              childCount: favourites.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Favourite product card ────────────────────────────────────────────────────
class _FavouriteCard extends StatelessWidget {
  final Product product;
  final AppLocalizations l10n;
  final AppStateProviderState state;

  const _FavouriteCard({
    required this.product,
    required this.l10n,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    final hasImage = p.imageUrls.isNotEmpty;
    final isOutOfStock = p.isOutOfStock;

    return GestureDetector(
      onTap: () => AppRouter.goToProduct(context, p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
          children: [
            // ── Image section ────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: ColorFiltered(
                      colorFilter: isOutOfStock
                          ? const ColorFilter.matrix([
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply),
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: p.imageUrls.first,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Shimmer.fromColors(
                                baseColor: AppColors.shimmerBase,
                                highlightColor: AppColors.shimmerHighlight,
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFFF5F5F5),
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 36,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            )
                          : Container(color: const Color(0xFFF5F5F5)),
                    ),
                  ),
                ),

                // Stock badge — top left
                if (p.isInStock || p.isLimitedStock)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _StockPill(
                      label: p.isInStock ? l10n.inStock : l10n.limitedStock,
                      color: p.isInStock
                          ? AppColors.primary
                          : AppColors.stockLimited,
                      textColor:
                          p.isInStock ? AppColors.textOnPrimary : Colors.white,
                    ),
                  ),
                if (isOutOfStock)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _StockPill(
                      label: l10n.outOfStock,
                      color: const Color(0xFFE8E8E8),
                      textColor: AppColors.textMuted,
                    ),
                  ),

                // Favourite heart — top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => state.toggleFavourite(p),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 17,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Text section ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    p.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Brand / category
                  Text(
                    p.category,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Price
                  Text(
                    p.formattedPrice,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // CTA button
                  _FavCTA(product: p, l10n: l10n, isOutOfStock: isOutOfStock),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CTA button (I'm Interested / Notify Me) ──────────────────────────────────
class _FavCTA extends StatelessWidget {
  final Product product;
  final AppLocalizations l10n;
  final bool isOutOfStock;

  const _FavCTA({
    required this.product,
    required this.l10n,
    required this.isOutOfStock,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutOfStock) {
      return SizedBox(
        width: double.infinity,
        height: 36,
        child: OutlinedButton(
          onPressed: () => _showNotifySnack(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            l10n.notifyMe,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton(
        onPressed: () => _showInterestedSnack(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          l10n.imInterested,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showInterestedSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added to cart — we\'ll follow up with you!',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
    context.appState.addToCart(product);
  }

  void _showNotifySnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'We\'ll notify you when it\'s back in stock.',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500, color: Colors.white),
        ),
        backgroundColor: AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Stock pill badge ──────────────────────────────────────────────────────────
class _StockPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StockPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
