// ─────────────────────────────────────────────────────────────────────────────
// PurchaseRequestService
//
// Manages purchase requests in Firestore.
// When a customer taps "Request Purchase" their cart is written here so the
// admin can see it on the Requests screen.
//
// Firestore schema  (collection: purchase_requests)
// ┌──────────────────────────────────────────────────────────────────────┐
// │  customerId   : String   (anonymous Firebase UID)                    │
// │  customerName : String                                               │
// │  customerPhone: String                                               │
// │  orderId      : String   (matching orders/{orderId} document)        │
// │  products     : List<Map>  [ { name, imageUrl, variant?, quantity } ]│
// │  status       : String   'new' | 'inDiscussion' | 'confirmed'        │
// │                          | 'rejected'                                 │
// │  createdAt    : Timestamp                                             │
// └──────────────────────────────────────────────────────────────────────┘
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/admin_request.dart';
import '../../shared/models/cart_item.dart';

class PurchaseRequestService {
  PurchaseRequestService._();
  static final PurchaseRequestService instance = PurchaseRequestService._();

  final _db = FirebaseFirestore.instance;
  static const _col = 'purchase_requests';

  // ── Customer: submit cart as a purchase request ────────────────────────────

  /// Writes a new purchase request document and returns its Firestore ID.
  /// [orderId] links this request to its corresponding orders/{orderId} doc
  /// so admin status changes can be reflected back to the customer.
  /// Throws on failure so the caller can surface the error to the user.
  Future<String> submitRequest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required List<CartItem> items,
    required String orderId,
  }) async {
    final ref = await _db.collection(_col).add({
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'orderId': orderId,
      'products': items
          .map((i) => {
                'name': i.product.name,
                'imageUrl': i.product.imageUrls.isNotEmpty
                    ? i.product.imageUrls.first
                    : '',
                'variant': i.variant.isNotEmpty ? i.variant : null,
                'quantity': i.quantity,
              })
          .toList(),
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ── Customer: live stream of their own requests ────────────────────────────

  /// Streams all purchase requests for a given customer phone number,
  /// newest first. Used by the customer-facing orders screen so status
  /// changes made by the admin appear in real time.
  Stream<List<AdminRequest>> watchRequestsByPhone(String phone) {
    return _db
        .collection(_col)
        .where('customerPhone', isEqualTo: phone)
        .snapshots()
        .handleError((error) {
      // ignore: avoid_print
      print('[PurchaseRequestService] watchRequestsByPhone error: $error');
    }).map((snap) {
      final requests =
          snap.docs.map(_docToAdminRequest).whereType<AdminRequest>().toList();
      requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return requests;
    });
  }

  // ── Admin: live stream of all requests, newest first ───────────────────────

  Stream<List<AdminRequest>> watchAllRequests() {
    // No orderBy — avoids requiring a Firestore composite index.
    // Sorting is done client-side after mapping.
    return _db.collection(_col).snapshots().handleError((error) {
      // ignore: avoid_print
      print('[PurchaseRequestService] watchAllRequests error: $error');
    }).map((snap) {
      final requests =
          snap.docs.map(_docToAdminRequest).whereType<AdminRequest>().toList();
      // Sort newest-first so no composite index is required.
      requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return requests;
    });
  }

  // ── Admin: status mutations ────────────────────────────────────────────────

  /// Updates the purchase request status and mirrors it to the linked
  /// orders document so the customer sees the change immediately.
  Future<void> updateStatus(
      String requestId, CustomerRequestStatus status) async {
    try {
      // 1. Update the purchase_request document itself.
      final reqRef = _db.collection(_col).doc(requestId);
      await reqRef.update({'status': _statusToString(status)});
      // ignore: avoid_print
      print(
          '[PurchaseRequestService] request $requestId → ${_statusToString(status)}');

      // 2. Mirror the status to the linked orders document.
      final snap = await reqRef.get();
      final orderId = snap.data()?['orderId'] as String?;
      // ignore: avoid_print
      print('[PurchaseRequestService] linked orderId: $orderId');

      if (orderId != null && orderId.isNotEmpty) {
        final orderStatus = _toOrderStatus(status);
        // ignore: avoid_print
        print(
            '[PurchaseRequestService] updating orders/$orderId → $orderStatus');
        await _db
            .collection('orders')
            .doc(orderId)
            .update({'status': orderStatus});
        // ignore: avoid_print
        print('[PurchaseRequestService] orders/$orderId updated ✓');
      } else {
        // ignore: avoid_print
        print(
            '[PurchaseRequestService] no orderId on request — order not synced');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[PurchaseRequestService] updateStatus error: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  AdminRequest? _docToAdminRequest(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final d = doc.data()!;

      final rawProducts = (d['products'] as List<dynamic>?) ?? [];
      final products = rawProducts.map((raw) {
        final m = raw as Map<String, dynamic>;
        final name = m['name'] as String? ?? '';
        final qty = (m['quantity'] as num?)?.toInt() ?? 1;
        final displayName = qty > 1 ? '$name (×$qty)' : name;
        return RequestedProduct(
          name: displayName,
          imageUrl: m['imageUrl'] as String? ?? '',
          variant: m['variant'] as String?,
        );
      }).toList();

      final statusStr = d['status'] as String? ?? 'new';
      final status = _statusFromString(statusStr);

      DateTime createdAt;
      final ts = d['createdAt'];
      if (ts is Timestamp) {
        createdAt = ts.toDate();
      } else {
        createdAt = DateTime.now();
      }

      return AdminRequest(
        id: doc.id,
        customerName: d['customerName'] as String? ?? 'Unknown',
        phone: d['customerPhone'] as String? ?? '',
        products: products,
        requestedAt: createdAt,
        status: status,
      );
    } catch (_) {
      return null;
    }
  }

  static CustomerRequestStatus _statusFromString(String s) {
    switch (s) {
      case 'inDiscussion':
        return CustomerRequestStatus.inDiscussion;
      case 'confirmed':
        return CustomerRequestStatus.confirmed;
      case 'rejected':
        return CustomerRequestStatus.rejected;
      default:
        return CustomerRequestStatus.newRequest;
    }
  }

  static String _statusToString(CustomerRequestStatus s) {
    switch (s) {
      case CustomerRequestStatus.inDiscussion:
        return 'inDiscussion';
      case CustomerRequestStatus.confirmed:
        return 'confirmed';
      case CustomerRequestStatus.rejected:
        return 'rejected';
      case CustomerRequestStatus.newRequest:
        return 'new';
    }
  }

  // ── Bulk deletion ──────────────────────────────────────────────────────────

  /// Deletes every purchase request document whose [customerPhone] matches
  /// [phone]. Uses batched writes (max 499 per batch).
  Future<void> deleteRequestsByPhone(String phone) async {
    final snap = await _db
        .collection(_col)
        .where('customerPhone', isEqualTo: phone)
        .get();
    await _deleteDocs(snap.docs);
  }

  /// Deletes every purchase request document whose [customerId] matches [uid].
  /// Covers requests written before the customer added a phone number.
  Future<void> deleteRequestsByUid(String uid) async {
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

  /// Maps admin request status → orders collection status string.
  ///
  /// confirmed    → completed   (admin confirmed the sale)
  /// inDiscussion → processing  (admin is actively working on it)
  /// rejected     → pending     (no good match; left as-is so the order
  ///                             stays visible to the customer)
  /// new          → pending     (no change yet)
  static String _toOrderStatus(CustomerRequestStatus s) {
    switch (s) {
      case CustomerRequestStatus.confirmed:
        return 'completed';
      case CustomerRequestStatus.inDiscussion:
        return 'processing';
      case CustomerRequestStatus.rejected:
      case CustomerRequestStatus.newRequest:
        return 'pending';
    }
  }
}
