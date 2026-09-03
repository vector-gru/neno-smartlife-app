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

  /// After admin signs out, re-establish the customer's anonymous session.
  /// If a previous anonymous UID is known we sign in anonymously (Firebase
  /// will create a new anonymous user since you can't re-authenticate with
  /// a plain anonymous account). The new UID is different from the old one,
  /// but `authStateChanges` will fire and the app will load the customer
  /// identity by phone number — so existing identity, favourites and orders
  /// are reconnected via the cross-device phone-matching logic already in
  /// [saveCustomerIdentity] and [watchOrdersByPhone].
  Future<void> restoreAnonymousSession(String? previousUid) async {
    if (previousUid == null) return;
    if (_auth.currentUser != null) return;
    final cred = await _auth.signInAnonymously();
    // Force-refresh token so subsequent Firestore writes are authenticated.
    await cred.user?.getIdToken(true);
  }

  // ── Customer anonymous auth ────────────────────────────────────────────────

  /// Returns the current anonymous user session, creating one if needed.
  ///
  /// IMPORTANT: if an admin (email/password) session is currently active this
  /// method returns that user unchanged — it never calls signInAnonymously()
  /// while an admin is signed in, which would overwrite the admin session.
  Future<User> ensureAnonymousSession() async {
    final user = _auth.currentUser;
    // Already have a session (admin or existing anonymous) — reuse it.
    if (user != null) return user;
    final cred = await _auth.signInAnonymously();
    final newUser = cred.user!;
    // Force-refresh the ID token so Firestore security rules receive a valid
    // auth token immediately on the first write. Without this, the token may
    // not have propagated yet and rules that check request.auth.uid fail.
    await newUser.getIdToken(true);
    return newUser;
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
  /// Returns null if no match found or if the query is denied (e.g. during
  /// the brief window after anonymous sign-in before the token propagates).
  Future<CustomerIdentity?> findCustomerByPhone(String phone) async {
    try {
      final snap = await _db
          .collection(_customersCollection)
          .where('phone', isEqualTo: phone.trim())
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return CustomerIdentity.fromMap(doc.id, doc.data());
    } catch (_) {
      // If the query is denied (e.g. token not yet propagated after fresh
      // anonymous sign-in), treat it as "no existing customer found" and
      // continue — the identity will be saved as a new document.
      return null;
    }
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
