// ─────────────────────────────────────────────────────────────────────────────
// InterestRequestService
//
// Two responsibilities:
//
//   CUSTOMER SIDE
//     recordInterest() — writes a document to `interest_requests` when a
//     customer taps "I'm Interested". The document carries customer name,
//     phone, product ID and product name.
//
//   ADMIN SIDE
//     watchNewRequests() — returns a stream of new (unseen) interest request
//     documents. AppStateProvider subscribes when the admin is logged in;
//     each emission triggers a local push notification via NotificationService.
//
// Firestore schema  (collection: interest_requests)
// ┌─────────────────────────────────────────────────┐
// │  customerId   : String   (anonymous UID)         │
// │  customerName : String                           │
// │  customerPhone: String                           │
// │  productId    : String                           │
// │  productName  : String                           │
// │  createdAt    : Timestamp                        │
// │  seenByAdmin  : bool     (default false)         │
// └─────────────────────────────────────────────────┘
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class InterestRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String productId;
  final String productName;
  final DateTime createdAt;

  const InterestRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.productId,
    required this.productName,
    required this.createdAt,
  });

  factory InterestRequest.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return InterestRequest(
      id: doc.id,
      customerId: d['customerId'] as String? ?? '',
      customerName: d['customerName'] as String? ?? '',
      customerPhone: d['customerPhone'] as String? ?? '',
      productId: d['productId'] as String? ?? '',
      productName: d['productName'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class InterestRequestService {
  InterestRequestService._();
  static final InterestRequestService instance = InterestRequestService._();

  final _db = FirebaseFirestore.instance;
  static const _collection = 'interest_requests';

  // ── Customer: record interest ──────────────────────────────────────────────

  /// Writes a new interest_request document to Firestore.
  /// Silently ignores errors so a Firestore hiccup never blocks the UI.
  Future<void> recordInterest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String productId,
    required String productName,
  }) async {
    try {
      await _db.collection(_collection).add({
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'productId': productId,
        'productName': productName,
        'createdAt': FieldValue.serverTimestamp(),
        'seenByAdmin': false,
      });
    } catch (_) {
      // Non-fatal — notification is best-effort.
    }
  }

  // ── Admin: watch for new requests ──────────────────────────────────────────

  /// Returns a stream that emits a list of *newly added* [InterestRequest]
  /// documents — i.e. only `DocumentChangeType.added` events after the
  /// listener is set up.
  ///
  /// We filter `seenByAdmin == false` and order by `createdAt` descending so
  /// the most recent items come first. Only documents from the last 30 days
  /// are considered to avoid re-firing old events on first listen.
  Stream<List<InterestRequest>> watchNewRequests() {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 30)),
    );
    return _db
        .collection(_collection)
        .where('seenByAdmin', isEqualTo: false)
        .where('createdAt', isGreaterThan: cutoff)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docChanges
            .where((c) => c.type == DocumentChangeType.added)
            .map((c) => InterestRequest.fromFirestore(c.doc))
            .toList());
  }

  /// Marks a request as seen so it doesn't re-notify on next app start.
  Future<void> markSeen(String requestId) async {
    try {
      await _db
          .collection(_collection)
          .doc(requestId)
          .update({'seenByAdmin': true});
    } catch (_) {}
  }
}
