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
// │  products     : List<Map>  [ { name, imageUrl, variant? } ]          │
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
  /// Throws on failure so the caller can surface the error to the user.
  Future<String> submitRequest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required List<CartItem> items,
  }) async {
    final ref = await _db.collection(_col).add({
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
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

  Future<void> updateStatus(String id, CustomerRequestStatus status) async {
    try {
      await _db
          .collection(_col)
          .doc(id)
          .update({'status': _statusToString(status)});
    } catch (_) {}
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
}
