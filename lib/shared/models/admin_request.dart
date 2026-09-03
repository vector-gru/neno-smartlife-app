/// Status for a customer product request.
enum CustomerRequestStatus { newRequest, inDiscussion, confirmed, rejected }

/// A single product line inside a customer request.
class RequestedProduct {
  final String name;
  final String imageUrl;
  final String? variant; // e.g. "256GB, Titanium"

  const RequestedProduct({
    required this.name,
    required this.imageUrl,
    this.variant,
  });
}

/// A customer product request in the admin dashboard.
class AdminRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String phone;
  final List<RequestedProduct> products;
  final DateTime requestedAt;
  CustomerRequestStatus status;
  final bool seenByAdmin;

  AdminRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.products,
    required this.requestedAt,
    this.status = CustomerRequestStatus.newRequest,
    this.seenByAdmin = false,
  });

  // ── Convenience getters used by the overview tab ──────────────────────────
  String get productName => products.isNotEmpty ? products.first.name : '';

  String get imageUrl => products.isNotEmpty ? products.first.imageUrl : '';

  /// Legacy "time ago" label derived from requestedAt.
  String get timeAgo {
    final diff = DateTime.now().difference(requestedAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  // ── Status helpers ─────────────────────────────────────────────────────────
  bool get isNew => status == CustomerRequestStatus.newRequest;
  bool get isInDiscussion => status == CustomerRequestStatus.inDiscussion;
  bool get isConfirmed => status == CustomerRequestStatus.confirmed;
  bool get isRejected => status == CustomerRequestStatus.rejected;
  bool get isPending => isNew || isInDiscussion;

  /// Human-readable label.
  String get statusLabel {
    switch (status) {
      case CustomerRequestStatus.newRequest:
        return 'New';
      case CustomerRequestStatus.inDiscussion:
        return 'In Discussion';
      case CustomerRequestStatus.confirmed:
        return 'Confirmed';
      case CustomerRequestStatus.rejected:
        return 'Rejected';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy alias — no longer needed, kept for safety during transition.
// Will be removed in a future cleanup.
// enum RequestStatus { pending, approved, rejected }
