import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/state/app_state.dart';
import '../../routes/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CustomerChatsScreen
//
// Shows all chat threads for the logged-in customer. Each thread card
// shows the product name, last message preview, and unread badge.
// Tapping opens the full ChatScreen.
// ─────────────────────────────────────────────────────────────────────────────

class CustomerChatsScreen extends StatelessWidget {
  const CustomerChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final state = context.appState;
    final customerId = state.customerIdentity?.uid ?? '';
    final customerPhone = state.customerIdentity?.phone ?? '';
    final customerName = state.customerIdentity?.fullName ?? '';

    // Prefer phone-based query — phone never drifts across anonymous sessions.
    final hasPhone = customerPhone.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: _buildAppBar(context),
      body: (!hasPhone && customerId.isEmpty)
          ? _buildIdentityRequired(context)
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
                  itemBuilder: (context, i) => _ThreadCard(
                    thread: threads[i],
                    onTap: () => AppRouter.goToChat(
                      context,
                      chatId: threads[i].id,
                      peerName: 'Neno SmartLife',
                      productName: threads[i].productName,
                      isAdmin: false,
                      senderId: customerId,
                      senderName: customerName,
                    ),
                  ),
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
      title: Text(
        'My Chats',
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
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
                Icons.chat_bubble_outline_rounded,
                size: 34,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you express interest in a product and the admin responds, your conversation will appear here.',
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

  Widget _buildIdentityRequired(BuildContext context) {
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
              'Add your name and phone number on the Account tab to start chatting with us.',
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
// Thread Card
// ─────────────────────────────────────────────────────────────────────────────

class _ThreadCard extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const _ThreadCard({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = thread.customerUnread > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x09000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF6D6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'N',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

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
                            _timeLabel(thread.lastMessageAt!),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: hasUnread
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 2),

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

                    if (thread.lastMessage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        thread.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: hasUnread
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontWeight:
                              hasUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ],
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

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }
}
