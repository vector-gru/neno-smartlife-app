import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/state/app_state.dart';
import '../../features/auth/customer_identity_sheet.dart';
import '../../routes/app_router.dart';

class AccountScreen extends StatefulWidget {
  /// Called when the user taps "My Orders" — lets the shell switch to tab 2.
  final VoidCallback? onGoToOrders;

  /// Called when the user taps "My Wishlist" — lets the shell push Favourites.
  final VoidCallback? onGoToWishlist;

  const AccountScreen({
    super.key,
    this.onGoToOrders,
    this.onGoToWishlist,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final l10n = context.l10n;
    final state = context.appState;
    final lang = LocaleProvider.of(context).language;

    final pendingCount = state.pendingOrders.length;
    final wishlistCount = state.favourites.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: _buildAppBar(l10n),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // ── Avatar + name + email ─────────────────────────────────────────
          _buildProfileHeader(),

          const SizedBox(height: 28),

          // ── Account section ───────────────────────────────────────────────
          _buildMenuCard(
            children: [
              _MenuRow(
                icon: Icons.inbox_outlined,
                iconBg: const Color(0xFFEEF6D6),
                title: l10n.accountMyOrders,
                subtitle: pendingCount > 0
                    ? '$pendingCount ${l10n.accountInTransit}'
                    : null,
                onTap: widget.onGoToOrders,
              ),
              _divider(),
              _MenuRow(
                icon: Icons.favorite_border_rounded,
                iconBg: const Color(0xFFEEF6D6),
                title: l10n.accountMyWishlist,
                subtitle: wishlistCount > 0
                    ? '$wishlistCount ${l10n.accountItemsSaved}'
                    : null,
                onTap: widget.onGoToWishlist,
              ),
              _divider(),
              _MenuRow(
                icon: Icons.location_on_outlined,
                iconBg: const Color(0xFFEEF6D6),
                title: l10n.accountShipping,
                subtitle: l10n.accountShippingSub,
                onTap: () => _showComingSoon(context, l10n),
              ),
              _divider(),
              _MenuRow(
                icon: Icons.credit_card_outlined,
                iconBg: const Color(0xFFEEF6D6),
                title: l10n.accountPayment,
                subtitle: l10n.accountPaymentSub,
                onTap: () => _showComingSoon(context, l10n),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Preferences section ───────────────────────────────────────────
          _buildSectionLabel(l10n.accountPreferences),
          const SizedBox(height: 8),
          _buildMenuCard(
            children: [
              _MenuRow(
                icon: Icons.language_rounded,
                iconBg: null,
                title: l10n.accountLanguage,
                trailingWidget: GestureDetector(
                  onTap: () => LocaleProvider.of(context).toggle(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang == AppLanguage.en ? 'English' : 'Français',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              _divider(),
              _MenuRow(
                icon: Icons.dark_mode_outlined,
                iconBg: null,
                title: l10n.accountDarkMode,
                trailingWidget: Transform.scale(
                  scale: 0.82,
                  child: Switch(
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primaryLight,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFDDDDDD),
                  ),
                ),
                showChevron: false,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Support section ───────────────────────────────────────────────
          _buildSectionLabel(l10n.accountSupport),
          const SizedBox(height: 8),
          _buildMenuCard(
            children: [
              _MenuRow(
                icon: Icons.help_outline_rounded,
                iconBg: null,
                title: l10n.accountHelpCenter,
                onTap: () => _showComingSoon(context, l10n),
              ),
              _divider(),
              _MenuRow(
                icon: Icons.headset_mic_outlined,
                iconBg: null,
                title: l10n.accountContactAdmin,
                titleColor: AppColors.primaryDark,
                onTap: () => AppRouter.goToCustomerChats(context),
              ),
              _divider(),
              _MenuRow(
                icon: Icons.share_rounded,
                iconBg: const Color(0xFFEEF6D6),
                title: 'Share the App',
                subtitle: 'Tell friends about Neno SmartLife',
                onTap: () => _shareApp(),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Clear history button ───────────────────────────────────────────
          _buildClearHistoryButton(context, l10n, state),

          const SizedBox(height: 12),

          // ── Delete account button (only visible when user has identity) ────
          if (state.hasIdentity) _buildDeleteAccountButton(context, state),
        ],
      ),
    );
  }

  // ─── App bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
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
        IconButton(
          tooltip: 'Admin',
          icon: const Icon(Icons.admin_panel_settings_outlined,
              color: AppColors.textPrimary, size: 24),
          onPressed: () => AppRouter.goToAdminArea(context),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Profile header ──────────────────────────────────────────────────────────
  Widget _buildProfileHeader() {
    final identity = context.appState.customerIdentity;
    final hasIdentity = identity != null;

    return Column(
      children: [
        // Avatar with primary-coloured ring
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2.5),
          ),
          child: ClipOval(
            child: Container(
              color: const Color(0xFFEEF6D6),
              child: hasIdentity
                  // Show first letter of name as monogram
                  ? Center(
                      child: Text(
                        identity.fullName.isNotEmpty
                            ? identity.fullName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      size: 52,
                      color: AppColors.primaryDark,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (hasIdentity) ...[
          // ── Known customer ──────────────────────────────────────────────
          Text(
            identity.fullName,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_outlined,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                identity.phone,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ] else ...[
          // ── Guest state ─────────────────────────────────────────────────
          Text(
            'Hello, Guest',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your name to personalise your experience',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              await CustomerIdentitySheet.show(context);
              setState(() {}); // refresh header after saving
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 14, color: AppColors.primaryDark),
                  const SizedBox(width: 6),
                  Text(
                    'Add your info',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
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
        children: children,
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        indent: 56,
        endIndent: 0,
        color: AppColors.divider,
      );

  Widget _buildClearHistoryButton(
    BuildContext context,
    AppLocalizations l10n,
    AppStateProviderState state,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmClearHistory(context, l10n, state),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.3),
          backgroundColor: AppColors.error.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.delete_sweep_outlined,
            color: AppColors.error, size: 20),
        label: Text(
          l10n.accountClearHistory,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }

  void _confirmClearHistory(
    BuildContext context,
    AppLocalizations l10n,
    AppStateProviderState state,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.accountClearHistoryConfirmTitle,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This will permanently delete your order history, purchase requests, '
          'interest signals, chat threads, saved favourites, and cart.\n\n'
          'Your name and phone number stay on the account. This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await state.clearHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'History cleared.',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not clear history. Please try again.',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
            child: Text(
              l10n.accountClearHistoryConfirm,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountButton(
    BuildContext context,
    AppStateProviderState state,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmDeleteAccount(context, state),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: AppColors.error.withValues(alpha: 0.5), width: 1.3),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.person_remove_outlined,
            color: AppColors.error, size: 20),
        label: Text(
          'Clear My Data',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(
    BuildContext context,
    AppStateProviderState state,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear My Data',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'This will permanently delete everything linked to your account — '
          'your name, phone number, saved favourites, order history, purchase '
          'requests, interest signals, and all chat conversations.\n\n'
          'If you rejoin with the same phone number it will be treated as a '
          'completely new account. This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Keep My Data',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await state.deleteAccount();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Your data has been cleared.',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                      backgroundColor: AppColors.textSecondary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not clear data. Please try again.',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete Everything',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareApp() async {
    const shareText =
        '📱✨ Check out Neno SmartLife — the free app to browse and order '
        'the latest phones, TVs, laptops, smart watches & more from '
        'Bafoussam, Cameroon. No sign-up needed!\n\n'
        'Download here: https://play.google.com/store/apps/details?id=com.hifivetech.neno_smartlife';

    XFile? imageFile;
    try {
      final ByteData data = await rootBundle.load('assets/store_icon.png');
      final Directory tmpDir = await getTemporaryDirectory();
      final File tmpFile = File('${tmpDir.path}/neno_smartlife_share.png');
      await tmpFile.writeAsBytes(data.buffer.asUint8List());
      imageFile = XFile(tmpFile.path, mimeType: 'image/png');
    } catch (e, st) {
      // Fall back to text-only if asset loading fails
      assert(() {
        debugPrint('_shareApp image load failed: $e\n$st');
        return true;
      }());
    }

    if (imageFile != null) {
      await Share.shareXFiles(
        [imageFile],
        subject: 'Neno SmartLife — Electronics Store App',
        text: shareText,
      );
    } else {
      await Share.share(shareText,
          subject: 'Neno SmartLife — Electronics Store App');
    }
  }

  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.comingSoon,
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

// ─── Menu row ──────────────────────────────────────────────────────────────────
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color? iconBg;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailingWidget;
  final bool showChevron;

  const _MenuRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.onTap,
    this.trailingWidget,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg ?? const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 19,
                color: iconBg != null
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Trailing: custom widget or chevron
            if (trailingWidget != null)
              trailingWidget!
            else if (showChevron)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
