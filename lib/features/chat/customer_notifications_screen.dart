import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/state/app_state.dart';
import '../../routes/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CustomerNotificationsScreen
//
// Shows all of the customer's chat threads as notification-style cards.
// Threads with unread messages from admin are highlighted. Tapping opens
// the chat. This screen is reached from the bell icon in the home app bar.
// ─────────────────────────────────────────────────────────────────────────────

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: _buildAppBar(context),
      body: (!hasPhone && customerId.isEmpty)
          ? _buildNoIdentity()
          : StreamBuilder<List<ChatThread>>(
              stream: hasPhone
                  ? ChatService.instance
                      .watchCustomerThreadsByPhone(customerPhone)
                  : ChatService.instance.watchCustomerThreads(customerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final threads = snapshot.data ?? [];

                if (threads.isEmpty) {
                  return _buildEmpty();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final thread = threads[i];
                    return _ChatNotifCard(
                      thread: thread,
                      onTap: () {
                        // Mark customer messages as read when opening
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
                  },
                );
              },
            ),
    );
  }

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
            'Messages from Neno SmartLife',
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
              'When Neno SmartLife replies to your interest,\nyou\'ll see it here.',
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
// Chat notification card
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

                    // Last message preview
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

              // Unread count badge
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
