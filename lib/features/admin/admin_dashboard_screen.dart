import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/data/mock_admin_requests.dart';
import '../../shared/models/admin_request.dart';
import 'admin_manage_categories_screen.dart';
import 'admin_products_screen.dart';
import 'admin_requests_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Dashboard Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _navIndex = 0;

  // Share the same list with the RequestsTab so approvals in overview
  // are reflected there too.
  late final List<AdminRequest> _requests = List.from(MockAdminRequests.all);

  void _approve(String id) {
    setState(() {
      final req = _requests.firstWhere((r) => r.id == id);
      req.status = CustomerRequestStatus.confirmed;
    });
  }

  void _dismiss(String id) {
    setState(() {
      final req = _requests.firstWhere((r) => r.id == id);
      req.status = CustomerRequestStatus.rejected;
    });
  }

  int get _pendingCount => _requests.where((r) => r.isPending).length;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _OverviewTab(
            requests: _requests,
            pendingCount: _pendingCount,
            onApprove: _approve,
            onDismiss: _dismiss,
            onBackToStore: () => Navigator.of(context).pop(),
            onViewAll: () => setState(() => _navIndex = 1),
          ),
          const _RequestsTab(),
          const AdminProductsScreen(),
          const _SettingsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom navigation ─────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Overview',
                selected: _navIndex == 0,
                onTap: () => setState(() => _navIndex = 0),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Requests',
                selected: _navIndex == 1,
                onTap: () => setState(() => _navIndex = 1),
              ),
              _NavItem(
                icon: Icons.inventory_2_outlined,
                label: 'Products',
                selected: _navIndex == 2,
                onTap: () => setState(() => _navIndex = 2),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                selected: _navIndex == 3,
                onTap: () => setState(() => _navIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview Tab
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final List<AdminRequest> requests;
  final int pendingCount;
  final void Function(String) onApprove;
  final void Function(String) onDismiss;
  final VoidCallback onBackToStore;
  final VoidCallback onViewAll;

  const _OverviewTab({
    required this.requests,
    required this.pendingCount,
    required this.onApprove,
    required this.onDismiss,
    required this.onBackToStore,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── App bar ────────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: AppColors.border,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.menu_rounded,
                color: AppColors.textPrimary, size: 26),
          ),
          title: Text(
            'Admin Dashboard',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          actions: [
            // Back to customer store
            IconButton(
              tooltip: 'Back to Store',
              icon: const Icon(Icons.storefront_outlined,
                  color: AppColors.textPrimary, size: 22),
              onPressed: onBackToStore,
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1511367461989-f85a21fda167?w=100',
                ),
                backgroundColor: AppColors.border,
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Stats grid ───────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(
                      child: _StatCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Total Products',
                        value: '142',
                        dark: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.receipt_long_rounded,
                        label: 'Pending Requests',
                        value: pendingCount.toString(),
                        dark: true,
                        hasIndicator: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_alt_outlined,
                        label: 'Active Customers',
                        value: '856',
                        dark: false,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Completed Sales',
                        value: '2,104',
                        dark: false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Revenue card ─────────────────────────────────────────
                const _RevenueCard(),

                const SizedBox(height: 28),

                // ── Recent Requests header ───────────────────────────────
                Row(
                  children: [
                    Text(
                      'Recent Requests',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onViewAll,
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ── Request list ─────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final req = requests[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RequestCard(
                    request: req,
                    onApprove: () => onApprove(req.id),
                    onDismiss: () => onDismiss(req.id),
                  ),
                );
              },
              childCount: requests.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool dark;
  final bool hasIndicator;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.dark,
    this.hasIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF1A1A1A) : Colors.white;
    final labelColor =
        dark ? Colors.white.withValues(alpha: 0.65) : AppColors.textSecondary;
    final valueColor = dark ? AppColors.primary : AppColors.textPrimary;
    final iconBg =
        dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF2F2F2);
    final iconColor = dark ? Colors.white : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: dark
            ? []
            : [
                const BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (hasIndicator) ...[
                const Spacer(),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Revenue Card
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  const _RevenueCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL REVENUE',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '15,400,000 FCFA',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      color: AppColors.success,
                      size: 13,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+12.5% this month',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Request Card
// ─────────────────────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final AdminRequest request;
  final VoidCallback onApprove;
  final VoidCallback onDismiss;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = request.isPending;
    final isConfirmed = request.isConfirmed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Product info row ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: request.imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 52,
                      height: 52,
                      color: const Color(0xFFF2F2F2),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: const Color(0xFFF2F2F2),
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + customer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.productName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            request.customerName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            ' · ${request.timeAgo}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMuted,
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

          // ── Divider ────────────────────────────────────────────────────
          const Divider(height: 1, color: Color(0xFFF2F2F2)),

          // ── Action row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                // Status chip
                _StatusChip(status: request.status),
                const Spacer(),
                if (isPending) ...[
                  // Dismiss button
                  GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Approve button
                  GestureDetector(
                    onTap: onApprove,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Approve',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    isConfirmed ? 'Confirmed ✓' : 'Rejected',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isConfirmed ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final CustomerRequestStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == CustomerRequestStatus.newRequest ||
        status == CustomerRequestStatus.inDiscussion;
    final isConfirmed = status == CustomerRequestStatus.confirmed;

    final Color bg = isPending
        ? const Color(0xFFEFF3FF)
        : isConfirmed
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFEF2F2);

    final Color textColor = isPending
        ? const Color(0xFF3B82F6)
        : isConfirmed
            ? AppColors.success
            : AppColors.error;

    final String label = switch (status) {
      CustomerRequestStatus.newRequest => 'New',
      CustomerRequestStatus.inDiscussion => 'In Discussion',
      CustomerRequestStatus.confirmed => 'Confirmed',
      CustomerRequestStatus.rejected => 'Rejected',
    };

    final IconData icon = isPending
        ? Icons.hourglass_top_rounded
        : isConfirmed
            ? Icons.check_circle_outline_rounded
            : Icons.cancel_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Nav Item
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? AppColors.textOnPrimary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder tabs
// ─────────────────────────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) => const AdminRequestsScreen();
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) => const _AdminSettingsScreen();
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Settings Screen
// ─────────────────────────────────────────────────────────────────────────────

class _AdminSettingsScreen extends StatelessWidget {
  const _AdminSettingsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          _SettingsSection(
            title: 'Catalog',
            items: [
              _SettingsItem(
                icon: Icons.category_rounded,
                label: 'Manage Categories',
                subtitle: 'Add, edit or remove product categories',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AdminManageCategoriesScreen())),
              ),
              _SettingsItem(
                icon: Icons.local_offer_rounded,
                label: 'Promotions & Discounts',
                subtitle: 'Create and manage sale campaigns',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.inventory_2_outlined,
                label: 'Inventory Alerts',
                subtitle: 'Set low-stock notification thresholds',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Orders & Payments',
            items: [
              _SettingsItem(
                icon: Icons.receipt_long_outlined,
                label: 'Order Management',
                subtitle: 'View and process customer orders',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.payment_rounded,
                label: 'Payment Methods',
                subtitle: 'Configure accepted payment gateways',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.local_shipping_outlined,
                label: 'Shipping & Delivery',
                subtitle: 'Set shipping zones and delivery fees',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Users & Permissions',
            items: [
              _SettingsItem(
                icon: Icons.people_alt_outlined,
                label: 'Customer Accounts',
                subtitle: 'View, search and manage customers',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin Roles',
                subtitle: 'Control staff access and permissions',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Store',
            items: [
              _SettingsItem(
                icon: Icons.storefront_outlined,
                label: 'Store Profile',
                subtitle: 'Update store name, logo and contact info',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                subtitle: 'Push and email notification preferences',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.bar_chart_rounded,
                label: 'Analytics & Reports',
                subtitle: 'Sales data, traffic and performance',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.language_rounded,
                label: 'Language & Region',
                subtitle: 'Default language, currency and timezone',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'System',
            items: [
              _SettingsItem(
                icon: Icons.backup_outlined,
                label: 'Backup & Export',
                subtitle: 'Export catalogue data as CSV or JSON',
                onTap: () {},
              ),
              _SettingsItem(
                icon: Icons.info_outline_rounded,
                label: 'About',
                subtitle: 'App version, licenses and support',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Section
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Container(
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
          child: Column(children: items),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Item (row)
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 19),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1, indent: 68, endIndent: 0, color: AppColors.divider),
      ],
    );
  }
}
