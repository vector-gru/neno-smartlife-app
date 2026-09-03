import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/interest_request_service.dart';
import '../../routes/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Notifications Screen
//
// Shows all interest requests. Tapping one marks it read; the chat icon
// opens a chat thread with that customer. Swipe-to-delete removes from
// Firestore.
// ─────────────────────────────────────────────────────────────────────────────

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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return _buildEmpty();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _NotificationCard(
              request: requests[i],
              onTap: () => _handleTap(context, requests[i]),
              onChat: () => _openChat(context, requests[i]),
              onDelete: () => _confirmDelete(context, requests[i].id),
            ),
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
            'Interest Requests',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Customers who expressed interest in products',
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
            'No interest requests yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'When customers tap "I\'m Interested",\nthey\'ll appear here.',
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

  // ── Actions ────────────────────────────────────────────────────────────────

  void _handleTap(BuildContext context, InterestRequest req) {
    if (!req.seenByAdmin) {
      InterestRequestService.instance.markSeen(req.id);
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Pass the screen's navigator context so the sheet can push routes
      // after it pops itself.
      builder: (_) => _RequestDetailSheet(
        request: req,
        screenContext: context,
      ),
    );
  }

  void _openChat(BuildContext context, InterestRequest req) async {
    if (!req.seenByAdmin) {
      InterestRequestService.instance.markSeen(req.id);
    }
    // Ensure the chat thread exists before navigating
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

  void _confirmDelete(BuildContext context, String requestId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete request?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This will permanently remove this interest request. The action cannot be undone.',
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
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await InterestRequestService.instance.deleteRequest(requestId);
            },
            child: Text(
              'Delete',
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Card
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final InterestRequest request;
  final VoidCallback onTap;
  final VoidCallback onChat;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.request,
    required this.onTap,
    required this.onChat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !request.seenByAdmin;

    return Dismissible(
      key: ValueKey(request.id),
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
        return false; // we handle deletion manually via dialog
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
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Unread dot / read indicator ──────────────────────────
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

                // ── Content ──────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer name + time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              request.customerName.isNotEmpty
                                  ? request.customerName
                                  : 'Anonymous',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            request.timeAgo,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Product interest line
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            const TextSpan(text: 'Interested in '),
                            TextSpan(
                              text: request.productName,
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

                      // Phone number
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            request.customerPhone,
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

                // ── Chat button ───────────────────────────────────────────
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onChat,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Request Detail Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RequestDetailSheet extends StatelessWidget {
  final InterestRequest request;
  final BuildContext screenContext;

  const _RequestDetailSheet({
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
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Text(
            'Interest Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMMM dd, yyyy • HH:mm').format(request.createdAt),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 20),

          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Customer',
            value: request.customerName.isNotEmpty
                ? request.customerName
                : 'Anonymous',
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: request.customerPhone.isNotEmpty
                ? request.customerPhone
                : 'Not provided',
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.inventory_2_outlined,
            label: 'Product',
            value: request.productName,
          ),

          const SizedBox(height: 28),

          // Chat CTA
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Pop the sheet first using the sheet's own context
                Navigator.of(context).pop();
                // Then set up thread and navigate using the screen's context
                await ChatService.instance.ensureThread(
                  chatId: request.id,
                  customerId: request.customerId,
                  customerName: request.customerName,
                  customerPhone: request.customerPhone,
                  productName: request.productName,
                );
                if (screenContext.mounted) {
                  AppRouter.goToChat(
                    screenContext,
                    chatId: request.id,
                    peerName: request.customerName,
                    productName: request.productName,
                    isAdmin: true,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(
                'Start Chat with ${request.customerName.isNotEmpty ? request.customerName.split(' ').first : 'Customer'}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
