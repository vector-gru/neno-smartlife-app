import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/state/app_state.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/profile/account_screen.dart';
import '../../shared/models/product.dart';
import '../../shared/widgets/app_search_bar.dart';
import '../../shared/widgets/condition_badge.dart';
import '../../shared/widgets/filter_chip_row.dart';
import '../../shared/widgets/product_image.dart';
import '../../shared/widgets/product_badge.dart';
import '../../shared/widgets/stock_chip.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/auth/customer_identity_sheet.dart';
import '../../routes/app_router.dart';

// ─── Promo banner data model ───────────────────────────────────────────────────
class _PromoBanner {
  final Color bgColor;
  final Color accentColor;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) subtitle;
  final IconData icon;

  const _PromoBanner({
    required this.bgColor,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

final _promoBanners = <_PromoBanner>[
  _PromoBanner(
    bgColor: const Color(0xFF0A0A0A),
    accentColor: AppColors.primary,
    title: (l) => l.promo1Title,
    subtitle: (l) => l.promo1Sub,
    icon: Icons.new_releases_rounded,
  ),
  _PromoBanner(
    bgColor: const Color(0xFF1A0F2E),
    accentColor: const Color(0xFF9B59B6),
    title: (l) => l.promo2Title,
    subtitle: (l) => l.promo2Sub,
    icon: Icons.recycling_rounded,
  ),
  _PromoBanner(
    bgColor: const Color(0xFF001A0F),
    accentColor: const Color(0xFF27AE60),
    title: (l) => l.promo3Title,
    subtitle: (l) => l.promo3Sub,
    icon: Icons.chat_bubble_outline_rounded,
  ),
];

// ─── HomeScreen ────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final bool showSignedOutBanner;

  const HomeScreen({super.key, this.showSignedOutBanner = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _bottomNavIndex = 0;
  int _bannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  bool _isSearching = false;
  final FocusNode _searchFocus = FocusNode();

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_bannerIndex + 1) % _promoBanners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.showSignedOutBanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Signed out successfully',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
    _startBannerTimer();
  }

  List<Product> get _filteredProducts {
    var products = context.appState.productsByCategory(_selectedCategory);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }
    // Pin featured products to the top (preserve relative order within each group)
    final featured = products.where((p) => p.featured).toList();
    final rest = products.where((p) => !p.featured).toList();
    return [...featured, ...rest];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    // Tab 0 = Home (uses shell AppBar)
    // Tabs 1, 2, 3 carry their own AppBars inside — shell AppBar is hidden.
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: _bottomNavIndex == 0 ? _buildAppBar(l10n) : null,
      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          // ── Tab 0: Home ────────────────────────────────────────────────────
          Column(
            children: [
              // Search bar — only visible when user activates search
              if (_isSearching)
                ColoredBox(
                  color: Colors.white,
                  child: AppSearchBar(
                    controller: _searchController,
                    hintText: l10n.searchHint,
                    focusNode: _searchFocus,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              _buildCategoryRow(l10n),
              Expanded(
                child: _filteredProducts.isEmpty
                    ? _buildEmpty(l10n)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                        itemCount: _filteredProducts.length + 1,
                        separatorBuilder: (_, i) => i == 0
                            ? const SizedBox.shrink()
                            : const SizedBox(height: 16),
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            // Banner only shown when not actively searching
                            return _isSearching
                                ? const SizedBox.shrink()
                                : _buildPromoBannerSection(l10n);
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child:
                                _ProductCard(product: _filteredProducts[i - 1]),
                          );
                        },
                      ),
              ),
            ],
          ),
          // ── Tab 1: Categories ─────────────────────────────────────────────
          const CategoriesScreen(),
          // ── Tab 2: Orders ──────────────────────────────────────────────────
          const OrdersScreen(),
          // ── Tab 3: Account ─────────────────────────────────────────────────
          AccountScreen(
            onGoToOrders: () => setState(() => _bottomNavIndex = 2),
            onGoToWishlist: () => AppRouter.goToFavourites(context),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(l10n),
    );
  }

  // ─── App bar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    final cartCount = context.appState.cartCount;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.border,
      leadingWidth: 48,
      leading: Padding(
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
        // Search icon / close button
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
              } else {
                // Focus the search field after the frame renders
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _searchFocus.requestFocus(),
                );
              }
            });
          },
        ),
        // Cart icon with live badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: AppColors.textPrimary, size: 22),
              onPressed: () => AppRouter.goToCart(context),
            ),
            if (cartCount > 0)
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
        // Admin dashboard shortcut
        IconButton(
          tooltip: 'Admin',
          icon: const Icon(Icons.admin_panel_settings_outlined,
              color: AppColors.textPrimary, size: 22),
          onPressed: () => AppRouter.goToAdminArea(context),
        ),
      ],
    );
  }

  // ─── Category chips ───────────────────────────────────────────────────────
  Widget _buildCategoryRow(AppLocalizations l10n) {
    final state = context.appState;
    final names = state.categoryNames; // ['All', ...from Firestore]
    final items = <String, String>{
      for (final cat in names) (cat == 'All' ? l10n.allCategories : cat): cat,
    };

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          FilterChipRow<String>(
            items: items,
            selected: _selectedCategory,
            onSelected: (v) => setState(() => _selectedCategory = v),
            paddingTop: 8,
            paddingBottom: 8,
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  // ─── Promo banner carousel ────────────────────────────────────────────────
  Widget _buildPromoBannerSection(AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _promoBanners.length,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemBuilder: (_, i) =>
                _BannerSlide(banner: _promoBanners[i], l10n: l10n),
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promoBanners.length, (i) {
            final active = i == _bannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 60, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            l10n.noProductsFound,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom nav ───────────────────────────────────────────────────────────
  Widget _buildBottomNav(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: l10n.navHome,
                isSelected: _bottomNavIndex == 0,
                onTap: () => setState(() => _bottomNavIndex = 0),
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: l10n.navCategories,
                isSelected: _bottomNavIndex == 1,
                onTap: () => setState(() => _bottomNavIndex = 1),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                label: l10n.navOrders,
                isSelected: _bottomNavIndex == 2,
                onTap: () => setState(() => _bottomNavIndex = 2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: l10n.navAccount,
                isSelected: _bottomNavIndex == 3,
                onTap: () => setState(() => _bottomNavIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Promo banner slide ────────────────────────────────────────────────────────
class _BannerSlide extends StatelessWidget {
  final _PromoBanner banner;
  final AppLocalizations l10n;

  const _BannerSlide({required this.banner, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: banner.bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative arc in background
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: banner.accentColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: banner.accentColor.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Icon
            Positioned(
              right: 20,
              bottom: 16,
              child: Icon(
                banner.icon,
                size: 64,
                color: banner.accentColor.withValues(alpha: 0.18),
              ),
            ),
            // Text content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title(l10n),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    banner.subtitle(l10n),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: banner.accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.shopNow,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: banner.bgColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom nav item ───────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product card ──────────────────────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final l10n = context.l10n;
    final state = context.appState;
    final isFavourite = state.isFavourite(p.id);

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
            // ── Image ───────────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: p.imageUrls.isNotEmpty
                        ? ProductImage(
                            url: p.imageUrls.first,
                            fit: BoxFit.cover,
                          )
                        : Container(color: const Color(0xFFF5F5F5)),
                  ),
                ),
                // Badge (NEW / HOT / SALE) — top left
                if (p.badge.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: ProductBadge(label: p.badge),
                  ),
                // Discount % badge — bottom right of image
                if (p.hasDiscount)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '-${p.discountPercent}%',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Condition pill — bottom left of image
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: ConditionBadge(condition: p.condition, compact: true),
                ),
                // Favourite — top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      // Require identity before saving a favourite.
                      if (!state.hasIdentity) {
                        final saved = await CustomerIdentitySheet.show(context);
                        if (!saved) return;
                      }
                      state.toggleFavourite(p);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Icon(
                        isFavourite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color:
                            isFavourite ? AppColors.error : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ── Content ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price — sale + optional strikethrough
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            p.formattedPrice,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (p.hasDiscount) ...[
                            Text(
                              p.formattedOriginalPrice!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    p.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Tags: category · stock · time
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _CategoryTag(p.category),
                      StockChip(stockStatus: p.stockStatus),
                      _TimeTag(p.addedAgo),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // CTA buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () {
                              state.addToCart(p);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added to cart!',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primaryDark,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              l10n.imInterested,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => AppRouter.goToCart(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.primary, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              if (state.isInCart(p.id))
                                Positioned(
                                  top: 7,
                                  right: 7,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;
  const _CategoryTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TimeTag extends StatelessWidget {
  final String label;
  const _TimeTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
