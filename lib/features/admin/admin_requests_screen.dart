import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'dart:async';

import '../../core/constants/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/purchase_request_service.dart';
import '../../routes/app_router.dart';
import '../../shared/models/admin_request.dart';
import '../../shared/widgets/app_search_bar.dart';
import '../../shared/widgets/filter_chip_row.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin – Customer Requests Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  final _service = PurchaseRequestService.instance;
  StreamSubscription<List<AdminRequest>>? _sub;

  List<AdminRequest> _requests = [];

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  CustomerRequestStatus? _filterStatus; // null = All

  static const _filterLabels = <String, CustomerRequestStatus?>{
    'All': null,
    'New': CustomerRequestStatus.newRequest,
    'In Discussion': CustomerRequestStatus.inDiscussion,
    'Confirmed': CustomerRequestStatus.confirmed,
    'Rejected': CustomerRequestStatus.rejected,
  };

  List<AdminRequest> get _filtered {
    var list = _requests;
    if (_filterStatus != null) {
      list = list.where((r) => r.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((r) =>
              r.customerName.toLowerCase().contains(q) ||
              r.phone.contains(q) ||
              r.products.any((p) => p.name.toLowerCase().contains(q)))
          .toList();
    }
    return list;
  }

  void _confirm(String id) {
    setState(() {
      _requests.firstWhere((r) => r.id == id).status =
          CustomerRequestStatus.confirmed;
    });
    _service.updateStatus(id, CustomerRequestStatus.confirmed);
  }

  /// Called when admin taps "Confirm & Close" on an inDiscussion card.
  /// Shows a warning that the chat thread will be deleted, then confirms
  /// and wipes the thread if the admin proceeds.
  void _confirmAndClose(String id) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm & close request?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This will mark the request as confirmed and permanently delete '
          'the entire message thread with this customer.\n\n'
          'The chat history cannot be recovered. Do you want to proceed?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.55,
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
              // 1. Optimistic local update
              setState(() {
                _requests.firstWhere((r) => r.id == id).status =
                    CustomerRequestStatus.confirmed;
              });
              // 2. Update status in Firestore (also notifies customer)
              await _service.updateStatus(id, CustomerRequestStatus.confirmed);
              // 3. Delete the chat thread and all its messages
              await ChatService.instance.deleteThread(id);
            },
            child: Text(
              'Confirm & Close',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reject(String id) {
    setState(() {
      _requests.firstWhere((r) => r.id == id).status =
          CustomerRequestStatus.rejected;
    });
    _service.updateStatus(id, CustomerRequestStatus.rejected);
  }

  void _startDiscussion(String id) async {
    setState(() {
      _requests.firstWhere((r) => r.id == id).status =
          CustomerRequestStatus.inDiscussion;
    });
    _service.updateStatus(id, CustomerRequestStatus.inDiscussion);
    final req = _requests.firstWhere((r) => r.id == id);
    await ChatService.instance.ensureThread(
      chatId: req.id,
      customerId: req.customerId.isNotEmpty ? req.customerId : req.id,
      customerName: req.customerName,
      customerPhone: req.phone,
      productName: req.productName,
    );
    if (mounted) {
      AppRouter.goToChat(
        context,
        chatId: req.id,
        peerName: req.customerName,
        productName: req.productName,
        isAdmin: true,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _sub = _service.watchAllRequests().listen(
          (list) => setState(() => _requests = list),
          // ignore: avoid_print
          onError: (e) => print('[AdminRequestsScreen] stream error: $e'),
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final requests = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        automaticallyImplyLeading: false,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Requests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Manage and process incoming product orders.',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        toolbarHeight: kToolbarHeight,
      ),
      body: Column(
        children: [
          // ── Search ─────────────────────────────────────────────────────
          ColoredBox(
            color: Colors.white,
            child: AppSearchBar(
              controller: _searchCtrl,
              hintText: 'Search requests...',
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // ── Filter chips ────────────────────────────────────────────────
          FilterChipRow<CustomerRequestStatus?>(
            items: _filterLabels,
            selected: _filterStatus,
            onSelected: (v) => setState(() => _filterStatus = v),
          ),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_outlined,
                            size: 52, color: AppColors.border),
                        const SizedBox(height: 12),
                        Text('No requests found',
                            style: GoogleFonts.poppins(
                                fontSize: 15, color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                    itemCount: requests.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _RequestCard(
                        request: requests[i],
                        onConfirm: () => requests[i].isInDiscussion
                            ? _confirmAndClose(requests[i].id)
                            : _confirm(requests[i].id),
                        onReject: () => _reject(requests[i].id),
                        onDiscuss: () => _startDiscussion(requests[i].id),
                      ),
                    ),
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
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onDiscuss;

  const _RequestCard({
    required this.request,
    required this.onConfirm,
    required this.onReject,
    required this.onDiscuss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            // ── Header: name + phone + status badge ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.customerName,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            request.phone,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: request.status),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),

            // ── Requested Products label ──────────────────────────────
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

            // ── Product rows ──────────────────────────────────────────
            ...request.products.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProductRow(product: p),
                )),

            const SizedBox(height: 4),

            // ── Timestamp ────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm')
                      .format(request.requestedAt),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

            // ── Action buttons ────────────────────────────────────────
            _ActionRow(
              request: request,
              onConfirm: onConfirm,
              onReject: onReject,
              onDiscuss: onDiscuss,
            ),
          ],
        ),
      ),
    );
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
// Action Row
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final AdminRequest request;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onDiscuss;

  const _ActionRow({
    required this.request,
    required this.onConfirm,
    required this.onReject,
    required this.onDiscuss,
  });

  @override
  Widget build(BuildContext context) {
    // Confirmed or rejected — show read-only state
    if (request.isConfirmed || request.isRejected) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: request.isConfirmed
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                request.isConfirmed ? 'Confirmed ✓' : 'Rejected',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      request.isConfirmed ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ),
          // Still allow messaging even on closed requests
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.chat_bubble_outline_rounded,
            color: AppColors.textSecondary,
            bgColor: const Color(0xFFF0F0F0),
            onTap: onDiscuss,
          ),
        ],
      );
    }

    // New request
    if (request.isNew) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onConfirm,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D00),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Confirm',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.chat_bubble_outline_rounded,
            color: AppColors.textSecondary,
            bgColor: const Color(0xFFF0F0F0),
            onTap: onDiscuss,
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.close_rounded,
            color: AppColors.error,
            bgColor: const Color(0xFFFEF2F2),
            onTap: onReject,
          ),
        ],
      );
    }

    // In Discussion
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onConfirm,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.background, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Confirm & Close',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _IconBtn(
          icon: Icons.chat_bubble_outline_rounded,
          color: AppColors.primary,
          bgColor: AppColors.primary.withValues(alpha: 0.12),
          onTap: onDiscuss,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small icon button
// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final CustomerRequestStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color text) = switch (status) {
      CustomerRequestStatus.newRequest => (
          const Color(0xFFEFF3FF),
          const Color(0xFF3B82F6)
        ),
      CustomerRequestStatus.inDiscussion => (
          const Color(0xFFF3E8FF),
          const Color(0xFF9333EA)
        ),
      CustomerRequestStatus.confirmed => (
          const Color(0xFFECFDF5),
          AppColors.success
        ),
      CustomerRequestStatus.rejected => (
          const Color(0xFFFEF2F2),
          AppColors.error
        ),
    };

    final label = switch (status) {
      CustomerRequestStatus.newRequest => 'New',
      CustomerRequestStatus.inDiscussion => 'In Discussion',
      CustomerRequestStatus.confirmed => 'Confirmed',
      CustomerRequestStatus.rejected => 'Rejected',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
