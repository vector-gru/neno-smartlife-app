import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_models.dart';

// ─── AuthService ──────────────────────────────────────────────────────────────
//
// Single source of truth for all Firebase Auth and Firestore identity work.

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _customersCollection = 'customers';

  // ── Auth state stream ──────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  bool get isAdmin {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  // ── Admin auth ─────────────────────────────────────────────────────────────

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Customer anonymous auth ────────────────────────────────────────────────

  Future<User> ensureAnonymousSession() async {
    final user = _auth.currentUser;
    if (user != null) return user;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  // ── Customer identity (Firestore) ──────────────────────────────────────────

  /// Saves the customer identity for the current anonymous session.
  ///
  /// Cross-device recognition: before writing, we search for an existing
  /// customer document with the same phone number. If found, we copy their
  /// favourites into the new UID's document so they feel recognised.
  Future<CustomerIdentity> saveCustomerIdentity({
    required String fullName,
    required String phone,
  }) async {
    final user = await ensureAnonymousSession();
    final trimmedPhone = phone.trim();

    // Look for an existing customer with this phone on a different UID.
    final existing = await findCustomerByPhone(trimmedPhone);

    final identity = CustomerIdentity(
      uid: user.uid,
      fullName: fullName.trim(),
      phone: trimmedPhone,
    );

    // Build the document — carry over favourites from the previous device if found.
    final Map<String, dynamic> data = identity.toMap();
    if (existing != null && existing.uid != user.uid) {
      // Restore favouriteIds from the previous session
      final oldDoc =
          await _db.collection(_customersCollection).doc(existing.uid).get();
      if (oldDoc.exists) {
        final oldFavs = oldDoc.data()?['favouriteIds'];
        if (oldFavs != null) data['favouriteIds'] = oldFavs;
      }
    }

    await _db
        .collection(_customersCollection)
        .doc(user.uid)
        .set(data, SetOptions(merge: true));

    return identity;
  }

  /// Fetches the stored customer identity for the current anonymous user.
  /// Returns null if no identity has been saved yet.
  Future<CustomerIdentity?> fetchCustomerIdentity() async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) return null;

    final doc = await _db.collection(_customersCollection).doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return CustomerIdentity.fromMap(user.uid, doc.data()!);
  }

  /// Looks up a customer document by phone number.
  /// Returns null if no match found.
  Future<CustomerIdentity?> findCustomerByPhone(String phone) async {
    final snap = await _db
        .collection(_customersCollection)
        .where('phone', isEqualTo: phone.trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return CustomerIdentity.fromMap(doc.id, doc.data());
  }

  // ── Account deletion ───────────────────────────────────────────────────────

  /// Deletes the customer's Firestore document and Firebase Auth account.
  /// After this the user is fully gone — no recovery.
  Future<void> deleteCurrentCustomerAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Delete Firestore identity document
    await _db.collection(_customersCollection).doc(user.uid).delete();

    // Delete the Firebase Auth account
    await user.delete();
  }

  // ── Auth error helpers ─────────────────────────────────────────────────────

  static String messageFromAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Sign in failed. Please try again.';
    }
  }
}
