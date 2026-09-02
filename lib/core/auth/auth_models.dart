// Auth models for Neno SmartLife.
//
// Two kinds of authenticated principals exist:
//   • Admin    — Firebase Auth user (email/password), manually created in console.
//   • Customer — Anonymous Firebase Auth user whose phone+name we store in
//                Firestore. Not a "real" account in the traditional sense.

// ─── CustomerIdentity ─────────────────────────────────────────────────────────

class CustomerIdentity {
  final String uid; // Firebase anonymous UID
  final String fullName;
  final String phone; // Primary identifier shown to admin

  const CustomerIdentity({
    required this.uid,
    required this.fullName,
    required this.phone,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'fullName': fullName,
        'phone': phone,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  factory CustomerIdentity.fromMap(String uid, Map<String, dynamic> map) {
    return CustomerIdentity(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }

  CustomerIdentity copyWith({String? fullName, String? phone}) {
    return CustomerIdentity(
      uid: uid,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
    );
  }
}

// ─── AuthStatus ───────────────────────────────────────────────────────────────

enum AuthStatus {
  /// Firebase has not finished restoring the previous session yet.
  loading,

  /// No Firebase Auth user — completely unauthenticated.
  unauthenticated,

  /// Signed in as an anonymous user; may or may not have a saved identity.
  customer,

  /// Signed in with email/password — this is an admin.
  admin,
}
