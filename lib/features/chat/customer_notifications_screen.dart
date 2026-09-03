import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/order_notification_service.dart';
import '../../core/state/app_state.dart';
import '../../routes/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CustomerNotificationsScreen
//
// Unified feed showing both order status notifications (confirmed / in
// discussion) and chat thread updates from the admin, merged and sorted
// newest-first. Each type has its own card design.
// ─────────────────────────────────────────────────────────────────────────────

// ── Unified entry ─────────────────────────────────────────────────────────────

enum _EntryType { orderStatus, chat }

class _Entry {
  final _EntryType type;
  final DateTime time;
  final OrderNotification? orderNotif;
  final ChatThread? chatThread;

  _Entry.orderStatus(OrderNotification n)
      : type = _EntryType.orderStatus,
        time = n.createdAt,
        orderNotif = n,
        chatThread = null;

  _Entry.chat(ChatThread t)
      : type = _EntryType.chat,
        time = t.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        orderNotif = null,
        chatThread = t;

  bool get isUnread => type == _EntryType.orderStatus
      ? !(orderNotif!.seenByCustomer)
      : (chatThread!.customerUnread > 0);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CustomerNotificationsScreen extends StatelessWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final state = context.appState;
    final customerId = state.customerIdentity?.uid ?? '';
    final customerPhone = state.customerIdentity?.phone ?? '';
    final customerName = state.customerIdentity?.fullName ?? '';
    final hasPhone = customerPhone.isNotEmpty;

    if (!hasPhone && customerId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: _buildAppBar(context),
        body: _buildNoIdentity(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: _buildAppBar(context),
      body: StreamBuilder<List<OrderNotification>>(
        stream: hasPhone
            ? OrderNotificationService.instance.watchByPhone(customerPhone)
            : OrderNotificationService.instance.watchByUid(customerId),
        builder: (context, orderSnap) {
          return StreamBuilder<List<ChatThread>>(
            stream: hasPhone
                ? ChatService.instance
                    .watchCustomerThreadsByPhone(customerPhone)
                : ChatService.instance.watchCustomerThreads(customerId),
            builder: (context, chatSnap) {
              final bothWaiting =
                  orderSnap.connectionState == ConnectionState.waiting &&
                      chatSnap.connectionState == ConnectionState.waiting;

              if (bothWaiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                );
              }

              final entries = <_Entry>[
                for (final n in orderSnap.data ?? []) _Entry.orderStatus(n),
                for (final t in chatSnap.data ?? []) _Entry.chat(t),
              ]..sort((a, b) => b.time.compareTo(a.time));

              if (entries.isEmpty) return _buildEmpty();

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final e = entries[i];
                  if (e.type == _EntryType.orderStatus) {
                    return _OrderStatusCard(
                      entry: e,
                      onTap: () {
                        OrderNotificationService.instance
                            .markSeen(e.orderNotif!.id);
                      },
                    );
                  } else {
                    final thread = e.chatThread!;
                    return _ChatNotifCard(
                      thread: thread,
                      onTap: () {
                        ChatService.instance.markCustomerRead(thread.id);
                        AppRouter.goToChat(
                          context,
                          chatId: thread.id,
                          peerName: 'Neno SmartLife',
                          productName: thread.productName,
                          isAdmin: false,
                          senderId: customerId,
                          senderName: customerName,
                        );
                      },
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
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Updates from Neno SmartLife',
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
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
                size: 34,
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
            const SizedBox(height: 8),
            Text(
              'Order updates and messages from\nNeno SmartLife will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoIdentity() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline_rounded,
                size: 52, color: AppColors.border),
            const SizedBox(height: 14),
            Text(
              'Introduce yourself first',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your name and phone on the Account tab to receive messages.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order status notification card
// ─────────────────────────────────────────────────────────────────────────────

class _OrderStatusCard extends StatelessWidget {
  final _Entry entry;
  final VoidCallback onTap;

  const _OrderStatusCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = entry.orderNotif!;
    final isUnread = entry.isUnread;
    final isConfirmed = n.isConfirmed;

    return GestureDetector(
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
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
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

              // Icon
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConfirmed
                      ? Icons.check_circle_outline_rounded
                      : Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: isConfirmed
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF1565C0),
                ),
              ),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.statusLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          n.timeAgo,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isUnread
                                ? AppColors.primaryDark
                                : AppColors.textMuted,
                            fontWeight:
                                isUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.bodyText,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight:
                            isUnread ? FontWeight.w500 : FontWeight.w400,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat notification card (unchanged design, lifted from original)
// ─────────────────────────────────────────────────────────────────────────────

class _ChatNotifCard extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const _ChatNotifCard({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = thread.customerUnread > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: hasUnread ? const Color(0xFFFAFFE8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: hasUnread
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
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
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
                    color: hasUnread ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: hasUnread
                        ? null
                        : Border.all(color: AppColors.border, width: 1.5),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Neno SmartLife',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight:
                                  hasUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (thread.lastMessageAt != null)
                          Text(
                            _timeAgo(thread.lastMessageAt!),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: hasUnread
                                  ? AppColors.primaryDark
                                  : AppColors.textMuted,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Product chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        thread.productName,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),

                    if (thread.lastMessage.isNotEmpty)
                      Text(
                        thread.lastMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: hasUnread
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight:
                              hasUnread ? FontWeight.w500 : FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),

              // Unread badge
              if (hasUnread) ...[
                const SizedBox(width: 10),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${thread.customerUnread}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
