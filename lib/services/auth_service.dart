import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> register(
      String email,
      String password,
      ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('Email is already registered');
        case 'invalid-email':
          throw Exception('Please enter a valid email');
        case 'weak-password':
          throw Exception('Password is too weak');
        default:
          throw Exception(e.message ?? 'Registration failed');
      }
    }
  }

  Future<UserCredential> login(
      String email,
      String password,
      ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email');
        case 'wrong-password':
          throw Exception('Incorrect password');
        case 'invalid-email':
          throw Exception('Invalid email address');
        case 'invalid-credential':
          throw Exception('Invalid email or password');
        case 'user-disabled':
          throw Exception('This account has been disabled');
        case 'too-many-requests':
          throw Exception(
            'Too many login attempts. Please try again later',
          );
        case 'network-request-failed':
          throw Exception(
            'No internet connection. Check your network',
          );
        default:
          throw Exception(e.message ?? 'Login failed');
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}