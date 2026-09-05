import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/chat_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quick-action template constants (admin only)
// ─────────────────────────────────────────────────────────────────────────────

const _kMomoNumber = '679362871';
const _kMomoName = 'Nelson Ngehmi';

/// Admin's WhatsApp short link — opens directly in the admin's inbox.
const _kAdminWhatsAppLink = 'https://wa.me/qr/TMOBUKHTEXKNG1';

// ── English ────────────────────────────────────────────────────────────────
const _kMomoTextEn = '💛 MTN MoMo Payment Details\n\n'
    'To complete your purchase, please send your payment to:\n\n'
    '📱 Number: $_kMomoNumber\n'
    '👤 Name: $_kMomoName\n\n'
    'Once payment is confirmed, we\'ll process your order right away. '
    'Thank you for choosing Neno SmartLife! 🛒';

const _kThankyouTextEn = '🙏 Thank You!\n\n'
    'We truly appreciate your trust in Neno SmartLife General Electronics. '
    'It\'s customers like you that keep us going!\n\n'
    'Come back soon — we\'ve always got cool deals waiting for you. '
    'See you next time! 😊✨';

// ── French ─────────────────────────────────────────────────────────────────
const _kMomoTextFr = '💛 Détails de Paiement MTN MoMo\n\n'
    'Pour finaliser votre achat, veuillez envoyer votre paiement à :\n\n'
    '📱 Numéro : $_kMomoNumber\n'
    '👤 Nom : $_kMomoName\n\n'
    'Dès confirmation du paiement, nous traiterons votre commande immédiatement. '
    'Merci de choisir Neno SmartLife ! 🛒';

const _kThankyouTextFr = '🙏 Merci !\n\n'
    'Nous apprécions sincèrement votre confiance en Neno SmartLife General Electronics. '
    'C\'est grâce à des clients comme vous que nous avançons !\n\n'
    'Revenez bientôt — nous avons toujours de super offres qui vous attendent. '
    'À très bientôt ! 😊✨';

// ─────────────────────────────────────────────────────────────────────────────
// ChatScreen
// ─────────────────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String senderName;
  final String peerName;
  final String productName;
  final bool isAdmin;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.peerName,
    required this.productName,
    required this.isAdmin,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _service = ChatService.instance;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markRead() {
    if (widget.isAdmin) {
      _service.markAdminRead(widget.chatId);
    } else {
      _service.markCustomerRead(widget.chatId);
    }
  }

  Future<void> _send({String? overrideText, String type = ''}) async {
    final text = (overrideText ?? _textController.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    if (overrideText == null) _textController.clear();

    try {
      await _service.sendMessage(
        chatId: widget.chatId,
        senderId: widget.senderId,
        senderName: widget.senderName,
        text: text,
        type: type,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  /// Sends the hand-off message in-chat then opens WhatsApp with a
  /// pre-written message referencing the product.
  Future<void> _continueOnWhatsApp() async {
    // 1. Post an automated message in the in-app thread first.
    await _send(
      overrideText: '👋 I\'d like to continue this conversation on WhatsApp. '
          'Please reach out to me there — I\'ll be messaging you about '
          '"${widget.productName}".',
    );

    // 2. Build the WhatsApp deep-link with a pre-written message.
    final waText = Uri.encodeComponent(
      'Hello Neno SmartLife! 👋\n\n'
      'I\'m interested in: *${widget.productName}*\n\n'
      'I was chatting with you on the Neno SmartLife app and would like '
      'to continue here. Could you help me with more details?',
    );
    final uri = Uri.parse('https://wa.me/qr/TMOBUKHTEXKNG1?text=$waText');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback: open the plain QR link without pre-filled text.
      await launchUrl(
        Uri.parse(_kAdminWhatsAppLink),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _ProductChip(productName: widget.productName),

          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _service.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyChat();
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                _markRead();

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == widget.senderId;
                    final showDate = i == 0 ||
                        !_isSameDay(messages[i - 1].createdAt, msg.createdAt);

                    return Column(
                      children: [
                        if (showDate) _DateSeparator(date: msg.createdAt),
                        // Render special bubble types
                        if (msg.isMomo)
                          _MomoBubble(
                            message: msg,
                            isMe: isMe,
                            showCopy: !widget.isAdmin,
                          )
                        else if (msg.isThankyou)
                          _ThankyouBubble(message: msg, isMe: isMe)
                        else
                          _MessageBubble(message: msg, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Admin-only quick-action bar
          if (widget.isAdmin)
            _QuickActionBar(
              onMomo: (lang) => _send(
                overrideText: lang == 'fr' ? _kMomoTextFr : _kMomoTextEn,
                type: 'momo',
              ),
              onThankyou: (lang) => _send(
                overrideText:
                    lang == 'fr' ? _kThankyouTextFr : _kThankyouTextEn,
                type: 'thankyou',
              ),
            ),

          // Customer-only WhatsApp hand-off bar
          if (!widget.isAdmin) _WhatsAppBar(onTap: _continueOnWhatsApp),

          _InputBar(
            controller: _textController,
            isSending: _isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
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
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF6D6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.peerName.isNotEmpty
                    ? widget.peerName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peerName.isNotEmpty ? widget.peerName : 'Customer',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Active',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textMuted),
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

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 30, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 14),
            Text(
              'Start the conversation',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Send a message below to connect about this product.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin quick-action bar
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionBar extends StatelessWidget {
  final void Function(String lang) onMomo;
  final void Function(String lang) onThankyou;

  const _QuickActionBar({required this.onMomo, required this.onThankyou});

  Future<void> _pickLanguage(
    BuildContext context, {
    required String label,
    required void Function(String) onPick,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LangPickerSheet(label: label, onPick: onPick),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Text(
            'Quick send:',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          _QuickBtn(
            label: '💛 MoMo Details',
            bgColor: const Color(0xFFFFF8DC),
            borderColor: const Color(0xFFFFCC00),
            textColor: const Color(0xFF7A5C00),
            onTap: () => _pickLanguage(
              context,
              label: 'MoMo Details',
              onPick: onMomo,
            ),
          ),
          const SizedBox(width: 8),
          _QuickBtn(
            label: '🙏 Thank You',
            bgColor: const Color(0xFFEEF6D6),
            borderColor: AppColors.primary,
            textColor: AppColors.primaryDark,
            onTap: () => _pickLanguage(
              context,
              label: 'Thank You',
              onPick: onThankyou,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language picker sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LangPickerSheet extends StatelessWidget {
  final String label;
  final void Function(String lang) onPick;

  const _LangPickerSheet({required this.label, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Send "$label" in…',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the language for this message.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _LangOption(
                  flag: '🇬🇧',
                  language: 'English',
                  onTap: () {
                    Navigator.of(context).pop();
                    onPick('en');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LangOption(
                  flag: '🇫🇷',
                  language: 'Français',
                  onTap: () {
                    Navigator.of(context).pop();
                    onPick('fr');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String language;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              language,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MoMo special bubble
// ─────────────────────────────────────────────────────────────────────────────

class _MomoBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showCopy;

  const _MomoBubble({
    required this.message,
    required this.isMe,
    required this.showCopy,
  });

  // Detect French variant by the French keyword in the stored text
  bool get _isFr => message.text.contains('Numéro');

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // MTN yellow card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFCC00), Color(0xFFFFAA00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF7A5C00).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('💛', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isFr ? 'Paiement MTN MoMo' : 'MTN MoMo Payment',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3D2C00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _momoRow(Icons.phone_rounded, _isFr ? 'Numéro' : 'Number',
                      _kMomoNumber),
                  const SizedBox(height: 6),
                  _momoRow(Icons.person_outline_rounded, _isFr ? 'Nom' : 'Name',
                      _kMomoName),
                  const SizedBox(height: 10),
                  Text(
                    _isFr
                        ? 'Envoyez votre paiement à ce numéro pour finaliser votre achat.'
                        : 'Send your payment to this number to complete your purchase.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF5C4000),
                      height: 1.4,
                    ),
                  ),
                  // Copy button — only on customer side
                  if (showCopy) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            const ClipboardData(text: _kMomoNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _isFr
                                      ? 'Numéro copié'
                                      : 'Number copied to clipboard',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF3D2C00),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF3D2C00).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF7A5C00), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded,
                                size: 14, color: Color(0xFF3D2C00)),
                            const SizedBox(width: 6),
                            Text(
                              _isFr ? 'Copier le numéro' : 'Copy number',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3D2C00),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _momoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF5C4000)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5C4000),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF3D2C00),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thank-you special bubble
// ─────────────────────────────────────────────────────────────────────────────

class _ThankyouBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _ThankyouBubble({required this.message, required this.isMe});

  // Detect French variant by the French keyword in the stored text
  bool get _isFr => message.text.contains('Merci');

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: isMe
                    ? []
                    : const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isFr ? '🙏 Merci !' : '🙏 Thank You!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isMe
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isMe
                            ? AppColors.textOnPrimary.withValues(alpha: 0.9)
                            : AppColors.textSecondary,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: _isFr
                              ? 'Nous apprécions sincèrement votre confiance en '
                              : 'We truly appreciate your trust in ',
                        ),
                        TextSpan(
                          text: 'Neno SmartLife General Electronics',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isMe
                                ? AppColors.textOnPrimary
                                : AppColors.primary,
                            height: 1.5,
                          ),
                        ),
                        TextSpan(
                          text: _isFr
                              ? '. C\'est grâce à des clients comme vous que nous avançons !'
                                  '\n\nRevenez bientôt — nous avons toujours de super offres qui vous attendent. '
                                  'À très bientôt ! 😊✨'
                              : '. It\'s customers like you that keep us going!'
                                  '\n\nCome back soon — we\'ve always got cool deals waiting. See you next time! 😊✨',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product context chip
// ─────────────────────────────────────────────────────────────────────────────

class _ProductChip extends StatelessWidget {
  final String productName;
  const _ProductChip({required this.productName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 13, color: AppColors.primaryDark),
                const SizedBox(width: 5),
                Text(
                  productName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
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
// Standard message bubble
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: isMe
                    ? []
                    : const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isMe ? AppColors.textOnPrimary : AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date separator
// ─────────────────────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _label(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border, height: 1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WhatsApp hand-off bar (customer only)
// ─────────────────────────────────────────────────────────────────────────────

class _WhatsAppBar extends StatelessWidget {
  final VoidCallback onTap;
  const _WhatsAppBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F9EE),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF25D366).withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // WhatsApp logo
              Image.asset(
                'assets/icons/whatsapp.png',
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Continue on WhatsApp',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF128C7E),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.open_in_new_rounded,
                size: 15,
                color: Color(0xFF25D366),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 10, 12, 10 + bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textMuted),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSending
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: AppColors.textOnPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: AppColors.textOnPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
