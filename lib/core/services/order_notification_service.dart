// ─────────────────────────────────────────────────────────────────────────────
// OrderNotificationService
//
// Manages the `customer_order_notifications` Firestore collection.
// The admin side writes a document when a purchase request is confirmed or
// moved to "in discussion". The customer side streams those documents to
// show in-app cards and trigger local push notifications.
//
// Firestore schema  (collection: customer_order_notifications)
// ┌──────────────────────────────────────────────────────────────────────┐
// │  customerId   : String   (anonymous Firebase UID)                    │
// │  customerPhone: String                                               │
// │  requestId    : String   (matching purchase_requests doc ID)         │
// │  productName  : String   (first product in the request)              │
// │  status       : String   'confirmed' | 'inDiscussion'                │
// │  seenByCustomer: bool    (default false)                             │
// │  createdAt    : Timestamp                                            │
// └──────────────────────────────────────────────────────────────────────┘
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderNotification {
  final String id;
  final String customerId;
  final String customerPhone;
  final String requestId;
  final String productName;
  final String status; // 'confirmed' | 'inDiscussion'
  final bool seenByCustomer;
  final DateTime createdAt;

  const OrderNotification({
    required this.id,
    required this.customerId,
    required this.customerPhone,
    required this.requestId,
    required this.productName,
    required this.status,
    required this.seenByCustomer,
    required this.createdAt,
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isInDiscussion => status == 'inDiscussion';

  String get statusLabel => isConfirmed ? 'Confirmed ✅' : 'In Discussion 💬';

  String get bodyText => isConfirmed
      ? 'Great news! Your request for $productName has been confirmed.'
      : 'Your request for $productName is now in discussion with our team.';

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} wk ago';
  }

  factory OrderNotification.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return OrderNotification(
      id: doc.id,
      customerId: d['customerId'] as String? ?? '',
      customerPhone: d['customerPhone'] as String? ?? '',
      requestId: d['requestId'] as String? ?? '',
      productName: d['productName'] as String? ?? '',
      status: d['status'] as String? ?? '',
      seenByCustomer: d['seenByCustomer'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class OrderNotificationService {
  OrderNotificationService._();
  static final OrderNotificationService instance = OrderNotificationService._();

  final _db = FirebaseFirestore.instance;
  static const _col = 'customer_order_notifications';

  // ── Admin: write a notification when status changes ────────────────────────

  /// Called by the admin side after updating a purchase request to
  /// `confirmed` or `inDiscussion`. Writes a document the customer streams.
  Future<void> notifyCustomer({
    required String customerId,
    required String customerPhone,
    required String requestId,
    required String productName,
    required String status,
  }) async {
    try {
      await _db.collection(_col).add({
        'customerId': customerId,
        'customerPhone': customerPhone,
        'requestId': requestId,
        'productName': productName,
        'status': status,
        'seenByCustomer': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // ignore: avoid_print
      print('[OrderNotificationService] notifyCustomer wrote doc OK '
          '(uid=$customerId, phone=$customerPhone, status=$status)');
    } catch (e) {
      // ignore: avoid_print
      print('[OrderNotificationService] notifyCustomer error: $e');
    }
  }

  // ── Customer: live stream of own notifications ─────────────────────────────

  /// Streams all order notifications for this customer (by phone),
  /// newest first. Used to populate the in-app notifications screen.
  Stream<List<OrderNotification>> watchByPhone(String phone) {
    return _db
        .collection(_col)
        .where('customerPhone', isEqualTo: phone)
        .snapshots()
        .handleError((e) {
      // ignore: avoid_print
      print('[OrderNotificationService] watchByPhone error: $e');
    }).map((snap) {
      final list = snap.docs.map(OrderNotification.fromFirestore).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Streams all order notifications for this customer (by UID),
  /// used as fallback when phone is not yet set.
  Stream<List<OrderNotification>> watchByUid(String uid) {
    return _db
        .collection(_col)
        .where('customerId', isEqualTo: uid)
        .snapshots()
        .handleError((e) {
      // ignore: avoid_print
      print('[OrderNotificationService] watchByUid error: $e');
    }).map((snap) {
      final list = snap.docs.map(OrderNotification.fromFirestore).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── Customer: delta stream for push notifications ─────────────────────────

  /// Emits only *newly added* unseen notifications for the given phone.
  /// Filters on a single field (customerPhone) to avoid requiring a
  /// composite index. Unseen + recency filtering is done client-side.
  Stream<List<OrderNotification>> watchNewByPhone(String phone) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _db
        .collection(_col)
        .where('customerPhone', isEqualTo: phone)
        .snapshots()
        .handleError((e) {
      // ignore: avoid_print
      print('[OrderNotificationService] watchNewByPhone error: $e');
    }).map((snap) => snap.docChanges
            .where((c) => c.type == DocumentChangeType.added)
            .map((c) => OrderNotification.fromFirestore(c.doc))
            .where((n) => !n.seenByCustomer && n.createdAt.isAfter(cutoff))
            .toList());
  }

  // ── Customer: mutations ────────────────────────────────────────────────────

  /// Marks a notification as seen (removes it from the unread count).
  Future<void> markSeen(String notificationId) async {
    try {
      await _db
          .collection(_col)
          .doc(notificationId)
          .update({'seenByCustomer': true});
    } catch (_) {}
  }

  /// Count of unseen notifications for a phone number.
  Stream<int> watchUnreadCount(String phone) {
    return _db
        .collection(_col)
        .where('customerPhone', isEqualTo: phone)
        .where('seenByCustomer', isEqualTo: false)
        .snapshots()
        .handleError((_) {})
        .map((snap) => snap.size);
  }

  // ── Bulk deletion (used by clearHistory / deleteAccount) ──────────────────

  Future<void> deleteByPhone(String phone) async {
    final snap = await _db
        .collection(_col)
        .where('customerPhone', isEqualTo: phone)
        .get();
    await _deleteDocs(snap.docs);
  }

  Future<void> deleteByUid(String uid) async {
    final snap =
        await _db.collection(_col).where('customerId', isEqualTo: uid).get();
    await _deleteDocs(snap.docs);
  }

  Future<void> _deleteDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (docs.isEmpty) return;
    const batchSize = 499;
    for (var i = 0; i < docs.length; i += batchSize) {
      final chunk = docs.skip(i).take(batchSize);
      final batch = _db.batch();
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
