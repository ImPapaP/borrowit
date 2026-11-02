import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Registration, login and logout with Firebase Authentication.
/// Student details (name, student ID) are saved in `users/{uid}`.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String name,
    required String studentId,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return;

    // The account exists at this point. If saving the profile fails, the
    // student can still use the app, so don't treat it as a failed sign-up.
    try {
      await user.updateDisplayName(name);
      await _db.collection('users').doc(user.uid).set({
        'name': name,
        'studentId': studentId,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('Could not save profile: $error');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// The student's profile from `users/{uid}`, or null if it doesn't exist.
  Future<Map<String, dynamic>?> profile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Turns Firebase errors into messages a student can understand.
  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address doesn\'t look right.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'No internet connection.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled in Firebase yet.';
        default:
          return error.message ?? 'Something went wrong (${error.code}).';
      }
    }
    return 'Something went wrong: $error';
  }
}
