import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/state/app_state.dart';
import '../../routes/app_router.dart';
import '../../shared/models/cart_item.dart';
import '../../shared/widgets/product_image.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final l10n = context.l10n;
    final state = context.appState;
    final items = state.cartItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: _buildAppBar(context, l10n),
      body: items.isEmpty
          ? _buildEmpty(context, l10n)
          : _buildContent(context, l10n, state, items),
    );
  }

  // ─── App bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
      BuildContext context, AppLocalizations l10n) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.border,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
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
      centerTitle: false,
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
              Icons.shopping_bag_outlined,
              size: 72,
              color: AppColors.textMuted.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.cartEmpty,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.cartEmptySub,
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

  // ─── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    AppStateProviderState state,
    List<CartItem> items,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Section heading
        Text(
          l10n.yourCart,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        // Cart item cards
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CartItemCard(
                item: item,
                onDecrement: () => state.updateCartQuantity(
                  item.product.id,
                  item.quantity - 1,
                ),
                onIncrement: () => state.updateCartQuantity(
                  item.product.id,
                  item.quantity + 1,
                ),
                onRemove: () => state.removeFromCart(item.product.id),
              ),
            )),

        const SizedBox(height: 8),

        // Summary card
        _buildSummaryCard(context, l10n, state, items),
      ],
    );
  }

  // ─── Summary card ───────────────────────────────────────────────────────────
  Widget _buildSummaryCard(
    BuildContext context,
    AppLocalizations l10n,
    AppStateProviderState state,
    List<CartItem> items,
  ) {
    final totalQty = items.fold<int>(0, (s, i) => s + i.quantity);

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Text(
            l10n.cartSummary,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Items row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.cartItems} ($totalQty)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                state.cartFormattedTotal,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.cartTotal,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                state.cartFormattedTotal,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Payment note
          Text(
            l10n.cartPaymentNote,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Request Purchase button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _onRequestPurchase(context, l10n, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text(
                l10n.requestPurchase,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Submit handler ─────────────────────────────────────────────────────────
  void _onRequestPurchase(
    BuildContext context,
    AppLocalizations l10n,
    AppStateProviderState state,
  ) {
    state.submitOrder();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order submitted successfully!',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.of(context).pop();
  }
}

// ─── Cart item card ────────────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.product;

    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 26),
      ),
      onDismissed: (_) => onRemove(),
      child: GestureDetector(
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: p.imageUrls.isNotEmpty
                        ? ProductImage(
                            url: p.imageUrls.first,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 28,
                              color: AppColors.textMuted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Details + stepper
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row + remove button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: onRemove,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Variant (color / storage) — shown only if set
                      if (item.variant.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.variant,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ] else if (p.selectedColor.isNotEmpty ||
                          p.colorOptions.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _variantLabel(p.selectedColor),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Quantity stepper + line total
                      Row(
                        children: [
                          _QuantityStepper(
                            quantity: item.quantity,
                            onDecrement: onDecrement,
                            onIncrement: onIncrement,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item.formattedLineTotal,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
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
        ),
      ),
    );
  }

  String _variantLabel(String hexColor) {
    final map = {
      '#C0C0C0': 'Silver',
      '#1A1A1A': 'Black',
      '#C68B2F': 'Gold',
      '#E8E0D4': 'Cream',
      '#2980B9': 'Blue',
      '#27AE60': 'Green',
      '#C0392B': 'Red',
      '#E0E0E0': 'White',
      '#F5F0EB': 'White',
      '#1B4332': 'Forest Green',
    };
    return map[hexColor] ?? hexColor;
  }
}

// ─── Quantity stepper ──────────────────────────────────────────────────────────
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement
          _StepperButton(
            icon: Icons.remove,
            onTap: onDecrement,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(9),
            ),
          ),
          // Count
          SizedBox(
            width: 36,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Increment
          _StepperButton(
            icon: Icons.add,
            onTap: onIncrement,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(9),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: borderRadius,
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}
