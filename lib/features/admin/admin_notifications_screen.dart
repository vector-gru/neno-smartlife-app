import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/interest_request_service.dart';
import '../../core/services/purchase_request_service.dart';
import '../../routes/app_router.dart';
import '../../shared/models/admin_request.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Notifications Screen
//
// Unified feed showing both interest requests (👋) and purchase requests (🛒),
// merged and sorted newest-first. Each type has its own card design and
// distinct action (chat vs. view request). Tapping marks as read.
// ─────────────────────────────────────────────────────────────────────────────

// ── Unified notification entry ────────────────────────────────────────────────

enum _NotifType { interest, purchase }

class _NotifEntry {
  final _NotifType type;
  final DateTime time;

  // Interest-specific
  final InterestRequest? interest;

  // Purchase-specific
  final AdminRequest? purchase;

  _NotifEntry.interest(InterestRequest req)
      : type = _NotifType.interest,
        time = req.createdAt,
        interest = req,
        purchase = null;

  _NotifEntry.purchase(AdminRequest req)
      : type = _NotifType.purchase,
        time = req.requestedAt,
        interest = null,
        purchase = req;
  bool get isUnread => type == _NotifType.interest
      ? !(interest!.seenByAdmin)
      : !(purchase!.seenByAdmin);

  String get id => type == _NotifType.interest ? interest!.id : purchase!.id;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context),
      body: StreamBuilder<List<InterestRequest>>(
        stream: InterestRequestService.instance.watchAllRequests(),
        builder: (context, interestSnap) {
          return StreamBuilder<List<AdminRequest>>(
            stream: PurchaseRequestService.instance.watchAllRequests(),
            builder: (context, purchaseSnap) {
              final bothWaiting =
                  interestSnap.connectionState == ConnectionState.waiting &&
                      purchaseSnap.connectionState == ConnectionState.waiting;

              if (bothWaiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                );
              }

              // Merge and sort newest-first
              final entries = <_NotifEntry>[
                for (final r in interestSnap.data ?? [])
                  _NotifEntry.interest(r),
                for (final r in purchaseSnap.data ?? [])
                  _NotifEntry.purchase(r),
              ]..sort((a, b) => b.time.compareTo(a.time));

              if (entries.isEmpty) return _buildEmpty();

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  if (entry.type == _NotifType.interest) {
                    return _InterestCard(
                      entry: entry,
                      onTap: () => _handleInterestTap(context, entry.interest!),
                      onChat: () => _openChat(context, entry.interest!),
                      onDelete: () => _confirmDeleteInterest(context, entry.id),
                    );
                  } else {
                    return _PurchaseCard(
                      entry: entry,
                      onTap: () => _handlePurchaseTap(context, entry.purchase!),
                      onDelete: () => _confirmDeletePurchase(context, entry.id),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.border,
      leadingWidth: 48,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Interest signals and purchase requests',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
      toolbarHeight: 62,
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 36,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Interest signals and purchase requests\nwill appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Interest actions ───────────────────────────────────────────────────────

  void _handleInterestTap(BuildContext context, InterestRequest req) {
    if (!req.seenByAdmin) InterestRequestService.instance.markSeen(req.id);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _InterestDetailSheet(request: req, screenContext: context),
    );
  }

  void _openChat(BuildContext context, InterestRequest req) async {
    if (!req.seenByAdmin) InterestRequestService.instance.markSeen(req.id);
    await ChatService.instance.ensureThread(
      chatId: req.id,
      customerId: req.customerId,
      customerName: req.customerName,
      customerPhone: req.customerPhone,
      productName: req.productName,
    );
    if (context.mounted) {
      AppRouter.goToChat(
        context,
        chatId: req.id,
        peerName: req.customerName,
        productName: req.productName,
        isAdmin: true,
      );
    }
  }

  void _confirmDeleteInterest(BuildContext context, String id) {
    _showDeleteDialog(
      context,
      onConfirm: () => InterestRequestService.instance.deleteRequest(id),
    );
  }

  // ── Purchase actions ───────────────────────────────────────────────────────

  void _handlePurchaseTap(BuildContext context, AdminRequest req) {
    if (!req.seenByAdmin) {
      PurchaseRequestService.instance.markPurchaseSeen(req.id);
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PurchaseDetailSheet(request: req),
    );
  }

  void _confirmDeletePurchase(BuildContext context, String id) {
    _showDeleteDialog(
      context,
      onConfirm: () async {
        // We only remove the notification entry — the purchase request itself
        // stays visible on the Requests screen for the admin to action.
        // Mark as seen so it disappears from the unread count.
        await PurchaseRequestService.instance.markPurchaseSeen(id);
      },
      body:
          'This will mark the purchase request as seen and remove it from this list.',
    );
  }

  // ── Shared delete dialog ───────────────────────────────────────────────────

  void _showDeleteDialog(
    BuildContext context, {
    required Future<void> Function() onConfirm,
    String? body,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove notification?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          body ??
              'This will permanently remove this notification. The action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await onConfirm();
            },
            child: Text('Remove',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card chrome
// ─────────────────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final bool isUnread;
  final String id;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Widget child;

  const _CardShell({
    required this.isUnread,
    required this.id,
    required this.onTap,
    required this.onDelete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFFAFFE8) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isUnread
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35), width: 1)
                : null,
            boxShadow: const [
              BoxShadow(
                  color: Color(0x09000000),
                  blurRadius: 8,
                  offset: Offset(0, 2)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Shared unread dot + content row layout ───────────────────────────────────

Widget _buildCardBody({
  required bool isUnread,
  required Widget typeChip,
  required Widget content,
  Widget? action,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unread dot
        Padding(
          padding: const EdgeInsets.only(top: 5, right: 10),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: isUnread ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: isUnread
                  ? null
                  : Border.all(color: AppColors.border, width: 1.5),
            ),
          ),
        ),
        // Main content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              typeChip,
              const SizedBox(height: 5),
              content,
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 10), action],
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Interest card
// ─────────────────────────────────────────────────────────────────────────────

class _InterestCard extends StatelessWidget {
  final _NotifEntry entry;
  final VoidCallback onTap;
  final VoidCallback onChat;
  final VoidCallback onDelete;

  const _InterestCard({
    required this.entry,
    required this.onTap,
    required this.onChat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final req = entry.interest!;
    final isUnread = entry.isUnread;

    return _CardShell(
      isUnread: isUnread,
      id: entry.id,
      onTap: onTap,
      onDelete: onDelete,
      child: _buildCardBody(
        isUnread: isUnread,
        typeChip: Row(
          children: [
            _TypeChip(
              label: '👋 Interest',
              color: AppColors.primary.withValues(alpha: 0.12),
              textColor: AppColors.primaryDark,
            ),
            const Spacer(),
            Text(
              req.timeAgo,
              style:
                  GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              req.customerName.isNotEmpty ? req.customerName : 'Anonymous',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'Interested in '),
                  TextSpan(
                    text: req.productName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(req.customerPhone,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
        action: GestureDetector(
          onTap: onChat,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 18, color: AppColors.primaryDark),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purchase card
// ─────────────────────────────────────────────────────────────────────────────

class _PurchaseCard extends StatelessWidget {
  final _NotifEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PurchaseCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final req = entry.purchase!;
    final isUnread = entry.isUnread;

    final productPreview = req.products.isEmpty
        ? 'No items'
        : req.products.length == 1
            ? req.products.first.name
            : '${req.products.first.name} + ${req.products.length - 1} more';

    return _CardShell(
      isUnread: isUnread,
      id: entry.id,
      onTap: onTap,
      onDelete: onDelete,
      child: _buildCardBody(
        isUnread: isUnread,
        typeChip: Row(
          children: [
            const _TypeChip(
              label: '🛒 Purchase Request',
              color: Color(0xFFE8F4FF),
              textColor: Color(0xFF1565C0),
            ),
            const Spacer(),
            Text(
              req.timeAgo,
              style:
                  GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              req.customerName.isNotEmpty ? req.customerName : 'Anonymous',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              productPreview,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(req.phone,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Type chip pill
// ─────────────────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _TypeChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
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

// ─────────────────────────────────────────────────────────────────────────────
// Interest detail sheet
// ─────────────────────────────────────────────────────────────────────────────

class _InterestDetailSheet extends StatelessWidget {
  final InterestRequest request;
  final BuildContext screenContext;

  const _InterestDetailSheet({
    required this.request,
    required this.screenContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dragHandle(),
          Text('Interest Details',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMMM dd, yyyy • HH:mm').format(request.createdAt),
            style:
                GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 20),
          _DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Customer',
              value: request.customerName.isNotEmpty
                  ? request.customerName
                  : 'Anonymous'),
          const SizedBox(height: 14),
          _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: request.customerPhone.isNotEmpty
                  ? request.customerPhone
                  : 'Not provided'),
          const SizedBox(height: 14),
          _DetailRow(
              icon: Icons.inventory_2_outlined,
              label: 'Product',
              value: request.productName),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await ChatService.instance.ensureThread(
                  chatId: request.id,
                  customerId: request.customerId,
                  customerName: request.customerName,
                  customerPhone: request.customerPhone,
                  productName: request.productName,
                );
                if (screenContext.mounted) {
                  AppRouter.goToChat(screenContext,
                      chatId: request.id,
                      peerName: request.customerName,
                      productName: request.productName,
                      isAdmin: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(
                'Start Chat with ${request.customerName.isNotEmpty ? request.customerName.split(' ').first : 'Customer'}',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purchase detail sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PurchaseDetailSheet extends StatelessWidget {
  final AdminRequest request;

  const _PurchaseDetailSheet({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dragHandle(),
          Text('Purchase Request',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMMM dd, yyyy • HH:mm').format(request.requestedAt),
            style:
                GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 20),
          _DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Customer',
              value: request.customerName.isNotEmpty
                  ? request.customerName
                  : 'Anonymous'),
          const SizedBox(height: 14),
          _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: request.phone.isNotEmpty ? request.phone : 'Not provided'),
          const SizedBox(height: 14),
          // Products list
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    size: 17, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            letterSpacing: 0.4)),
                    const SizedBox(height: 4),
                    ...request.products.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(p.name,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.flag_outlined,
            label: 'Status',
            value: request.statusLabel,
          ),
          const SizedBox(height: 28),
          Text(
            'Manage this request from the Requests screen.',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _dragHandle() {
  return Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.4)),
              const SizedBox(height: 1),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
