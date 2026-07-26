/// Represents a pending product request in the admin dashboard.
enum RequestStatus { pending, approved, rejected }

class AdminRequest {
  final String id;
  final String productName;
  final String customerName;
  final String timeAgo;
  final String imageUrl;
  RequestStatus status;

  AdminRequest({
    required this.id,
    required this.productName,
    required this.customerName,
    required this.timeAgo,
    required this.imageUrl,
    this.status = RequestStatus.pending,
  });
}
