import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign up user dengan email dan password, lalu simpan data tambahan ke Firestore
  Future<String?> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan data tambahan ke Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'phone': phone,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // sukses
    } on FirebaseAuthException catch (e) {
      return e.message; // kirim error ke UI
    } catch (e) {
      return e.toString();
    }
  }

  /// Login user dengan email dan password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // sukses
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Logout user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Cek user yang sedang login
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Stream perubahan auth (untuk listener)
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}
