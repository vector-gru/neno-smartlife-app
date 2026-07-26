import '../models/admin_request.dart';

class MockAdminRequests {
  MockAdminRequests._();

  static List<AdminRequest> all = [
    AdminRequest(
      id: 'req_1',
      customerName: 'Jean-Pierre',
      phone: '+237 671 234 567',
      products: const [
        RequestedProduct(
          name: 'Samsung S24 Ultra (256GB, Titaniu...',
          imageUrl:
              'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=200',
          variant: '256GB, Titanium',
        ),
      ],
      requestedAt: DateTime(2023, 10, 12, 10, 45),
      status: CustomerRequestStatus.newRequest,
    ),
    AdminRequest(
      id: 'req_2',
      customerName: 'Marie Claire',
      phone: '+237 699 888 777',
      products: const [
        RequestedProduct(
          name: 'Sony WH-1000XM5',
          imageUrl:
              'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=200',
        ),
        RequestedProduct(
          name: 'Protective Hard Case',
          imageUrl:
              'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=200',
        ),
      ],
      requestedAt: DateTime(2023, 10, 11, 14, 20),
      status: CustomerRequestStatus.inDiscussion,
    ),
    AdminRequest(
      id: 'req_3',
      customerName: 'Oumarou',
      phone: '+237 655 321 098',
      products: const [
        RequestedProduct(
          name: 'MacBook Pro 16"',
          imageUrl:
              'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=200',
          variant: 'M3 Pro, 18GB RAM',
        ),
      ],
      requestedAt: DateTime(2023, 10, 10, 9, 0),
      status: CustomerRequestStatus.confirmed,
    ),
    AdminRequest(
      id: 'req_4',
      customerName: 'Fatima D.',
      phone: '+237 677 112 233',
      products: const [
        RequestedProduct(
          name: 'iPad Pro 12.9"',
          imageUrl:
              'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=200',
          variant: 'M4, 256GB, WiFi',
        ),
        RequestedProduct(
          name: 'Apple Pencil Pro',
          imageUrl:
              'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=200',
        ),
      ],
      requestedAt: DateTime(2023, 10, 9, 16, 55),
      status: CustomerRequestStatus.newRequest,
    ),
    AdminRequest(
      id: 'req_5',
      customerName: 'Kofi A.',
      phone: '+237 691 445 667',
      products: const [
        RequestedProduct(
          name: 'Apple Watch Ultra 2',
          imageUrl:
              'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=200',
          variant: '49mm, Alpine Loop',
        ),
      ],
      requestedAt: DateTime(2023, 10, 8, 11, 30),
      status: CustomerRequestStatus.rejected,
    ),
    AdminRequest(
      id: 'req_6',
      customerName: 'Aminata S.',
      phone: '+237 650 778 990',
      products: const [
        RequestedProduct(
          name: 'Samsung 55" QLED 4K',
          imageUrl:
              'https://images.unsplash.com/photo-1593784991095-a205069470b6?w=200',
        ),
        RequestedProduct(
          name: 'HDMI 2.1 Cable (2m)',
          imageUrl:
              'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=200',
        ),
      ],
      requestedAt: DateTime(2023, 10, 7, 8, 15),
      status: CustomerRequestStatus.inDiscussion,
    ),
  ];
}
