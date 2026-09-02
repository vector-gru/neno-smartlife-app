import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_models.dart';

// ─── AuthService ──────────────────────────────────────────────────────────────
//
// Single source of truth for all Firebase Auth and Firestore identity work.
// Consumed by AuthStateProvider in app_state.dart.

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection where customer identities are stored.
  static const _customersCollection = 'customers';

  // ── Auth state stream ──────────────────────────────────────────────────────

  /// Emits a [User?] every time the Firebase Auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// True if the current user signed in with email/password (i.e. admin).
  bool get isAdmin {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  // ── Admin auth ─────────────────────────────────────────────────────────────

  /// Sign in with email and password.
  /// Throws [FirebaseAuthException] on failure — callers should catch and
  /// map [exception.code] to a user-friendly message.
  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out regardless of role.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Customer anonymous auth ────────────────────────────────────────────────

  /// Signs in anonymously if no user is currently signed in.
  /// Returns the anonymous [User].
  Future<User> ensureAnonymousSession() async {
    final user = _auth.currentUser;
    if (user != null) return user;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  // ── Customer identity (Firestore) ──────────────────────────────────────────

  /// Saves or overwrites the customer identity document in Firestore.
  Future<CustomerIdentity> saveCustomerIdentity({
    required String fullName,
    required String phone,
  }) async {
    final user = await ensureAnonymousSession();
    final identity = CustomerIdentity(
      uid: user.uid,
      fullName: fullName.trim(),
      phone: phone.trim(),
    );
    await _db
        .collection(_customersCollection)
        .doc(user.uid)
        .set(identity.toMap(), SetOptions(merge: true));
    return identity;
  }

  /// Fetches the stored customer identity for the current anonymous user.
  /// Returns null if no identity has been saved yet.
  Future<CustomerIdentity?> fetchCustomerIdentity() async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) return null;

    final doc =
        await _db.collection(_customersCollection).doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return CustomerIdentity.fromMap(user.uid, doc.data()!);
  }

  // ── Auth error helpers ─────────────────────────────────────────────────────

  /// Maps a [FirebaseAuthException] code to a readable message.
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
