// ─────────────────────────────────────────────────────────────────────────────
// ChatService
//
// Each interest request gets its own chat thread. The chat ID equals the
// interest_request document ID, making it trivial to link from the
// notification screen to the right conversation.
//
// Firestore schema
// ┌── chats/{chatId} ─────────────────────────────────────────────────┐
// │  interestRequestId : String  (= chatId)                           │
// │  customerId        : String                                        │
// │  customerName      : String                                        │
// │  customerPhone     : String                                        │
// │  productName       : String                                        │
// │  lastMessage       : String  (preview)                            │
// │  lastMessageAt     : Timestamp                                     │
// │  adminUnread       : int     (messages customer sent, unseen)      │
// │  customerUnread    : int     (messages admin sent, unseen)         │
// │                                                                    │
// │  messages/{msgId}                                                  │
// │    text       : String                                             │
// │    senderId   : String  ('admin' | anonymous UID)                 │
// │    senderName : String                                             │
// │    createdAt  : Timestamp                                          │
// │    isRead     : bool                                               │
// └───────────────────────────────────────────────────────────────────┘
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── ChatMessage ──────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String text;
  final String senderId; // 'admin' or customer anonymous UID
  final String senderName;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.isRead = false,
  });

  bool get isAdmin => senderId == 'admin';

  factory ChatMessage.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ChatMessage(
      id: doc.id,
      text: d['text'] as String? ?? '',
      senderId: d['senderId'] as String? ?? '',
      senderName: d['senderName'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: d['isRead'] as bool? ?? false,
    );
  }
}

// ─── ChatThread (summary doc at chats/{chatId}) ───────────────────────────────

class ChatThread {
  final String id; // == interestRequestId
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String productName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int adminUnread;
  final int customerUnread;

  const ChatThread({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.productName,
    required this.lastMessage,
    this.lastMessageAt,
    this.adminUnread = 0,
    this.customerUnread = 0,
  });

  factory ChatThread.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ChatThread(
      id: doc.id,
      customerId: d['customerId'] as String? ?? '',
      customerName: d['customerName'] as String? ?? '',
      customerPhone: d['customerPhone'] as String? ?? '',
      productName: d['productName'] as String? ?? '',
      lastMessage: d['lastMessage'] as String? ?? '',
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate(),
      adminUnread: d['adminUnread'] as int? ?? 0,
      customerUnread: d['customerUnread'] as int? ?? 0,
    );
  }
}

// ─── ChatService ──────────────────────────────────────────────────────────────

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _db = FirebaseFirestore.instance;
  static const _chats = 'chats';
  static const _messages = 'messages';

  // ── Ensure thread exists ───────────────────────────────────────────────────

  /// Creates the chat thread document if it doesn't exist yet.
  /// Safe to call multiple times (uses SetOptions.merge).
  Future<void> ensureThread({
    required String chatId,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String productName,
  }) async {
    await _db.collection(_chats).doc(chatId).set({
      'interestRequestId': chatId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'productName': productName,
      'lastMessage': '',
      'adminUnread': 0,
      'customerUnread': 0,
    }, SetOptions(merge: true));
  }

  // ── Send message ───────────────────────────────────────────────────────────

  /// Appends a message to the thread and bumps the unread counter for the
  /// other party.
  Future<void> sendMessage({
    required String chatId,
    required String senderId, // 'admin' or customer UID
    required String senderName,
    required String text,
  }) async {
    final batch = _db.batch();

    // Add the message document
    final msgRef =
        _db.collection(_chats).doc(chatId).collection(_messages).doc();

    batch.set(msgRef, {
      'text': text.trim(),
      'senderId': senderId,
      'senderName': senderName,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update thread summary + bump the *other* party's unread counter
    final threadRef = _db.collection(_chats).doc(chatId);
    final isAdmin = senderId == 'admin';

    batch.update(threadRef, {
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      // When admin sends, increment customerUnread; and vice-versa
      if (isAdmin) 'customerUnread': FieldValue.increment(1),
      if (!isAdmin) 'adminUnread': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // ── Watch messages ─────────────────────────────────────────────────────────

  /// Real-time stream of messages for a thread, oldest first.
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _db
        .collection(_chats)
        .doc(chatId)
        .collection(_messages)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  // ── Watch all threads (admin) ──────────────────────────────────────────────

  /// All chat threads with at least one message, most recently active first.
  Stream<List<ChatThread>> watchAllThreads() {
    return _db
        .collection(_chats)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatThread.fromFirestore).toList());
  }

  // ── Watch thread for customer ──────────────────────────────────────────────

  /// Live stream of threads for this customer, matched by UID.
  Stream<List<ChatThread>> watchCustomerThreads(String customerId) {
    return _db
        .collection(_chats)
        .where('customerId', isEqualTo: customerId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatThread.fromFirestore).toList());
  }

  /// Live stream of threads matched by phone number.
  /// Used as a fallback when the customer's anonymous UID has changed
  /// across sessions (e.g. after admin logout restored a new anonymous UID).
  Stream<List<ChatThread>> watchCustomerThreadsByPhone(String phone) {
    return _db
        .collection(_chats)
        .where('customerPhone', isEqualTo: phone)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatThread.fromFirestore).toList());
  }

  // ── Unread count ───────────────────────────────────────────────────────────

  /// Total unread messages waiting for the admin across all threads.
  Stream<int> watchAdminUnreadCount() {
    return _db
        .collection(_chats)
        .where('adminUnread', isGreaterThan: 0)
        .snapshots()
        .map((snap) => snap.docs.fold<int>(
            0, (acc, doc) => acc + (doc['adminUnread'] as int? ?? 0)));
  }

  /// Total unread messages for this specific customer (by UID).
  Stream<int> watchCustomerUnreadCount(String customerId) {
    return _db
        .collection(_chats)
        .where('customerId', isEqualTo: customerId)
        .where('customerUnread', isGreaterThan: 0)
        .snapshots()
        .map((snap) => snap.docs.fold<int>(
            0, (acc, doc) => acc + (doc['customerUnread'] as int? ?? 0)));
  }

  /// Unread count matched by phone — used when the customer UID may differ
  /// from the one stored on the thread (cross-session UID drift).
  Stream<int> watchCustomerUnreadCountByPhone(String phone) {
    return _db
        .collection(_chats)
        .where('customerPhone', isEqualTo: phone)
        .where('customerUnread', isGreaterThan: 0)
        .snapshots()
        .map((snap) => snap.docs.fold<int>(
            0, (acc, doc) => acc + (doc['customerUnread'] as int? ?? 0)));
  }

  // ── Mark read ──────────────────────────────────────────────────────────────

  /// Reset the unread counter for the viewer's side.
  Future<void> markAdminRead(String chatId) async {
    try {
      await _db.collection(_chats).doc(chatId).update({'adminUnread': 0});
    } catch (_) {}
  }

  Future<void> markCustomerRead(String chatId) async {
    try {
      await _db.collection(_chats).doc(chatId).update({'customerUnread': 0});
    } catch (_) {}
  }
}
