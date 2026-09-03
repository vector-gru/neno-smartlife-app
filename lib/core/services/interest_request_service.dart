// ─────────────────────────────────────────────────────────────────────────────
// InterestRequestService
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
  final bool seenByAdmin;

  const InterestRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.productId,
    required this.productName,
    required this.createdAt,
    this.seenByAdmin = false,
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
      seenByAdmin: d['seenByAdmin'] as bool? ?? false,
    );
  }

  /// Relative time label, e.g. "2 min ago", "3 hr ago", "Yesterday".
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} wk ago';
  }
}

class InterestRequestService {
  InterestRequestService._();
  static final InterestRequestService instance = InterestRequestService._();

  final _db = FirebaseFirestore.instance;
  static const _collection = 'interest_requests';

  // ── Customer: record interest ──────────────────────────────────────────────

  /// Writes a new interest_request document to Firestore.
  Future<String?> recordInterest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String productId,
    required String productName,
  }) async {
    try {
      final ref = await _db.collection(_collection).add({
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'productId': productId,
        'productName': productName,
        'createdAt': FieldValue.serverTimestamp(),
        'seenByAdmin': false,
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  // ── Admin: full live list ──────────────────────────────────────────────────

  /// All interest requests from the past 90 days, newest first.
  /// Used by the notification screen to render the full list.
  Stream<List<InterestRequest>> watchAllRequests() {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 90)),
    );
    return _db
        .collection(_collection)
        .where('createdAt', isGreaterThan: cutoff)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(InterestRequest.fromFirestore).toList());
  }

  /// Stream of the current unread count (seenByAdmin == false).
  /// Lightweight — used for the badge on the notification bell.
  Stream<int> watchUnreadCount() {
    return _db
        .collection(_collection)
        .where('seenByAdmin', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

  // ── Admin: delta stream for push notifications ────────────────────────────

  /// Emits only *newly added* unseen requests — triggers local push
  /// notification in AppStateProvider when the admin is logged in.
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

  // ── Admin: mutations ───────────────────────────────────────────────────────

  /// Marks a request as read (seenByAdmin = true).
  Future<void> markSeen(String requestId) async {
    try {
      await _db
          .collection(_collection)
          .doc(requestId)
          .update({'seenByAdmin': true});
    } catch (_) {}
  }

  /// Permanently deletes an interest request document from Firestore.
  Future<void> deleteRequest(String requestId) async {
    await _db.collection(_collection).doc(requestId).delete();
  }

  // ── Bulk deletion ──────────────────────────────────────────────────────────

  /// Deletes every interest request whose [customerPhone] matches [phone].
  Future<void> deleteRequestsByPhone(String phone) async {
    final snap = await _db
        .collection(_collection)
        .where('customerPhone', isEqualTo: phone)
        .get();
    await _deleteDocs(snap.docs);
  }

  /// Deletes every interest request whose [customerId] matches [uid].
  /// Covers requests recorded before the customer added a phone number.
  Future<void> deleteRequestsByUid(String uid) async {
    final snap = await _db
        .collection(_collection)
        .where('customerId', isEqualTo: uid)
        .get();
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
