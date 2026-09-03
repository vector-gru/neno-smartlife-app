import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/purchase_request_service.dart';
import '../../core/state/app_state.dart';
import '../../routes/app_router.dart';
import '../../shared/models/admin_request.dart';
import '../../shared/widgets/filter_chip_row.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Customer – My Requests / Orders Screen
// ─────────────────────────────────────────────────────────────────────────────

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _service = PurchaseRequestService.instance;
  StreamSubscription<List<AdminRequest>>? _sub;

  List<AdminRequest> _requests = [];
  CustomerRequestStatus? _filter; // null = All
  bool _subscribed = false;

  static const _filterLabels = <String, CustomerRequestStatus?>{
    'All': null,
    'Pending': CustomerRequestStatus.newRequest,
    'In Discussion': CustomerRequestStatus.inDiscussion,
    'Confirmed': CustomerRequestStatus.confirmed,
    'Rejected': CustomerRequestStatus.rejected,
  };

  List<AdminRequest> get _filtered {
    if (_filter == null) return _requests;
    return _requests.where((r) => r.status == _filter).toList();
  }

  void _subscribe() {
    if (_subscribed) return;
    final phone = context.appState.customerIdentity?.phone ?? '';
    if (phone.isEmpty) return;
    _subscribed = true;
    _sub = _service.watchRequestsByPhone(phone).listen(
      (list) {
        if (mounted) setState(() => _requests = list);
      },
      // ignore: avoid_print
      onError: (e) => print('[OrdersScreen] stream error: $e'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final l10n = context.l10n;
    final state = context.appState;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: _buildAppBar(context, l10n, state),
      body: Column(
        children: [
          // ── Filter chips ───────────────────────────────────────────────────
          FilterChipRow<CustomerRequestStatus?>(
            items: _filterLabels,
            selected: _filter,
            onSelected: (v) => setState(() => _filter = v),
          ),

          // ── List ───────────────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmpty(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _RequestCard(request: _filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── App bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    AppStateProviderState state,
  ) {
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appName,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'My Requests',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: AppColors.textPrimary, size: 22),
              onPressed: () => AppRouter.goToCart(context),
            ),
            if (state.cartCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            'No requests yet',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to your cart and\ntap Request Purchase to get started.',
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Request Card — mirrors admin _RequestCard but read-only for the customer
// ─────────────────────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final AdminRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isInDiscussion = request.isInDiscussion;
    final state = context.appState;
    final customerId = state.customerIdentity?.uid ?? '';
    final customerName = state.customerIdentity?.fullName ?? '';

    Widget card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isInDiscussion
            ? Border.all(
                color: const Color(0xFF9333EA).withValues(alpha: 0.3), width: 1)
            : null,
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: timestamp + status badge ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm')
                      .format(request.requestedAt),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                _StatusBadge(status: request.status),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),

            // ── Products label ─────────────────────────────────────────────
            Text(
              'REQUESTED PRODUCTS',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            // ── Product rows ───────────────────────────────────────────────
            ...request.products.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProductRow(product: p),
                )),

            // ── Status message ─────────────────────────────────────────────
            if (request.isConfirmed ||
                request.isRejected ||
                request.isInDiscussion) ...[
              const SizedBox(height: 4),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 10),
              _StatusMessage(status: request.status),
            ],

            // ── Open chat CTA for inDiscussion ────────────────────────────
            if (isInDiscussion) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => _openChat(context, customerId, customerName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text(
                    'Open Discussion',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return card;
  }

  Future<void> _openChat(
      BuildContext context, String customerId, String customerName) async {
    // Ensure the thread exists (idempotent — safe to call if already created)
    await ChatService.instance.ensureThread(
      chatId: request.id,
      customerId: customerId.isNotEmpty ? customerId : request.id,
      customerName: customerName,
      customerPhone: request.phone,
      productName: request.productName,
    );
    if (context.mounted) {
      AppRouter.goToChat(
        context,
        chatId: request.id,
        peerName: 'Neno SmartLife',
        productName: request.productName,
        isAdmin: false,
        senderId: customerId,
        senderName: customerName,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Row
// ─────────────────────────────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  final RequestedProduct product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: product.imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  width: 40, height: 40, color: const Color(0xFFEEEEEE)),
              errorWidget: (_, __, ___) => Container(
                width: 40,
                height: 40,
                color: const Color(0xFFEEEEEE),
                child: const Icon(Icons.image_outlined,
                    size: 18, color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              product.variant != null
                  ? '${product.name} (${product.variant})'
                  : product.name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge — identical palette to the admin screen
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final CustomerRequestStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color text) = switch (status) {
      CustomerRequestStatus.newRequest => (
          const Color(0xFFEFF3FF),
          const Color(0xFF3B82F6),
        ),
      CustomerRequestStatus.inDiscussion => (
          const Color(0xFFF3E8FF),
          const Color(0xFF9333EA),
        ),
      CustomerRequestStatus.confirmed => (
          const Color(0xFFECFDF5),
          AppColors.success,
        ),
      CustomerRequestStatus.rejected => (
          const Color(0xFFFEF2F2),
          AppColors.error,
        ),
    };

    final label = switch (status) {
      CustomerRequestStatus.newRequest => 'Pending',
      CustomerRequestStatus.inDiscussion => 'In Discussion',
      CustomerRequestStatus.confirmed => 'Confirmed',
      CustomerRequestStatus.rejected => 'Rejected',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Message — contextual note shown at the bottom of each card
// ─────────────────────────────────────────────────────────────────────────────

class _StatusMessage extends StatelessWidget {
  final CustomerRequestStatus status;
  const _StatusMessage({required this.status});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String message) = switch (status) {
      CustomerRequestStatus.inDiscussion => (
          Icons.chat_bubble_outline_rounded,
          const Color(0xFF9333EA),
          'The store is reviewing your request and will contact you shortly.',
        ),
      CustomerRequestStatus.confirmed => (
          Icons.check_circle_outline_rounded,
          AppColors.success,
          'Your request has been confirmed! The store will reach out to finalise the purchase.',
        ),
      CustomerRequestStatus.rejected => (
          Icons.cancel_outlined,
          AppColors.error,
          'This request was not accepted. Feel free to contact the store for more info.',
        ),
      _ => (
          Icons.info_outline_rounded,
          AppColors.textMuted,
          '',
        ),
    };

    if (message.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
