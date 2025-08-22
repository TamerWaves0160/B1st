import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  const AuthService();
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> get onAuthChanged => _auth.authStateChanges();

  Future<UserCredential> createAccount({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<UserCredential> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }
}