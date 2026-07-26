import '../models/admin_request.dart';

class MockAdminRequests {
  MockAdminRequests._();

  static List<AdminRequest> all = [
    AdminRequest(
      id: 'req_1',
      productName: 'Samsung S24 Ultra',
      customerName: 'Jean-Pierre',
      timeAgo: '10 mins ago',
      imageUrl:
          'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=200',
    ),
    AdminRequest(
      id: 'req_2',
      productName: 'Sony WH-1000XM5',
      customerName: 'Marie K.',
      timeAgo: '1 hour ago',
      imageUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=200',
    ),
    AdminRequest(
      id: 'req_3',
      productName: 'MacBook Pro 16',
      customerName: 'Oumarou',
      timeAgo: '3 hours ago',
      imageUrl:
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=200',
    ),
    AdminRequest(
      id: 'req_4',
      productName: 'iPad Pro 12.9"',
      customerName: 'Fatima D.',
      timeAgo: '5 hours ago',
      imageUrl:
          'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=200',
    ),
    AdminRequest(
      id: 'req_5',
      productName: 'Apple Watch Ultra 2',
      customerName: 'Kofi A.',
      timeAgo: '8 hours ago',
      imageUrl:
          'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=200',
    ),
  ];
}
