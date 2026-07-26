import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/data/mock_admin_requests.dart';
import '../../shared/models/admin_request.dart';
import 'admin_products_screen.dart';

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

  // Local copy so we can mutate status in place
  late final List<AdminRequest> _requests = MockAdminRequests.all
      .map((r) => AdminRequest(
            id: r.id,
            productName: r.productName,
            customerName: r.customerName,
            timeAgo: r.timeAgo,
            imageUrl: r.imageUrl,
            status: r.status,
          ))
      .toList();

  void _approve(String id) {
    setState(() {
      final req = _requests.firstWhere((r) => r.id == id);
      req.status = RequestStatus.approved;
    });
  }

  void _dismiss(String id) {
    setState(() {
      final req = _requests.firstWhere((r) => r.id == id);
      req.status = RequestStatus.rejected;
    });
  }

  int get _pendingCount =>
      _requests.where((r) => r.status == RequestStatus.pending).length;

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

  const _OverviewTab({
    required this.requests,
    required this.pendingCount,
    required this.onApprove,
    required this.onDismiss,
    required this.onBackToStore,
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
                      onTap: () {},
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
    final isPending = request.status == RequestStatus.pending;
    final isApproved = request.status == RequestStatus.approved;

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
                  // Resolved — show label only
                  Text(
                    isApproved ? 'Approved ✓' : 'Rejected',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isApproved ? AppColors.success : AppColors.error,
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
  final RequestStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == RequestStatus.pending;
    final isApproved = status == RequestStatus.approved;

    final Color bg = isPending
        ? const Color(0xFFEFF3FF)
        : isApproved
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFEF2F2);

    final Color textColor = isPending
        ? const Color(0xFF3B82F6)
        : isApproved
            ? AppColors.success
            : AppColors.error;

    final String label = isPending
        ? 'Pending'
        : isApproved
            ? 'Approved'
            : 'Rejected';

    final IconData icon = isPending
        ? Icons.hourglass_top_rounded
        : isApproved
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
  Widget build(BuildContext context) => const _PlaceholderView(
      label: 'Requests', icon: Icons.receipt_long_rounded);
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) =>
      const _PlaceholderView(label: 'Settings', icon: Icons.settings_rounded);
}

class _PlaceholderView extends StatelessWidget {
  final String label;
  final IconData icon;
  const _PlaceholderView({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.border),
            const SizedBox(height: 12),
            Text(
              'Coming soon',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
