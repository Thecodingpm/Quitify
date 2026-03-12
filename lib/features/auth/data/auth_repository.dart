import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final googleSignInProvider = Provider<GoogleSignIn>((_) => GoogleSignIn());

class AuthRepository {
  AuthRepository(this._auth, this._firestore, this._googleSignIn);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    DateTime? quitDate,
    int? cigarettesPerDay,
    double? packPrice,
    double? yearsSmoking,
    String? reasonForQuitting,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _ensureUserProfile(
      credential.user!,
      name: name,
      quitDate: quitDate,
      cigarettesPerDay: cigarettesPerDay,
      packPrice: packPrice,
      yearsSmoking: yearsSmoking,
      reasonForQuitting: reasonForQuitting,
    );
    return credential;
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _ensureUserProfile(credential.user!);
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'abort', message: 'Google sign-in aborted');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    await _ensureUserProfile(result.user!, name: result.user?.displayName);
    return result;
  }

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final result = await _auth.signInWithCredential(oauthCredential);
    final fullName = [appleCredential.givenName, appleCredential.familyName].whereType<String>().join(' ').trim();
    await _ensureUserProfile(result.user!, name: fullName.isNotEmpty ? fullName : null);
    return result;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> _ensureUserProfile(
    User user, {
    String? name,
    DateTime? quitDate,
    int? cigarettesPerDay,
    double? packPrice,
    double? yearsSmoking,
    String? reasonForQuitting,
  }) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final snapshot = await doc.get();
    final existing = snapshot.data();

    final profile = <String, dynamic>{
      'user_id': user.uid,
      'name': name ?? user.displayName ?? existing?['name'] ?? '',
      'email': user.email ?? existing?['email'] ?? '',
      'quit_date': quitDate != null
          ? Timestamp.fromDate(quitDate)
          : (existing != null ? existing['quit_date'] : null),
      'cigarettes_per_day': cigarettesPerDay ?? existing?['cigarettes_per_day'] ?? 0,
      'pack_price': packPrice ?? existing?['pack_price'] ?? 0.0,
      'years_smoking': yearsSmoking ?? existing?['years_smoking'] ?? 0.0,
      'reason_for_quitting': reasonForQuitting ?? existing?['reason_for_quitting'] ?? '',
      'current_streak': existing?['current_streak'] ?? 0,
      'total_cigarettes_avoided': existing?['total_cigarettes_avoided'] ?? 0,
      'total_money_saved': existing?['total_money_saved'] ?? 0,
      'total_cravings_logged': existing?['total_cravings_logged'] ?? 0,
      'premium_status': existing?['premium_status'] ?? 'free',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': existing?['createdAt'] ?? FieldValue.serverTimestamp(),
    };

    await doc.set(profile, SetOptions(merge: true));
  }
}

String _generateNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}

String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    ref.watch(googleSignInProvider),
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
