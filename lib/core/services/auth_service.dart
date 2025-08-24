import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String mobileNumber,
    required String role,
  }) async {
    try {
      // Check if phone number already exists
      final querySnapshot = await _firestore.collection('users').where('mobileNumber', isEqualTo: mobileNumber).limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        throw FirebaseAuthException(code: 'phone-number-already-in-use', message: 'This mobile number is already registered.');
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': name,
          'mobileNumber': mobileNumber,
          'email': email,
          'role': role,
          'createdAt': Timestamp.now(),
        });
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.message}');
      return null;
    }
  }

  // This is the corrected sign-in function without the keepLoggedIn parameter
  Future<UserCredential?> signInWithPhoneAndPassword({
    required String mobileNumber,
    required String password,
  }) async {
    try {
      final querySnapshot = await _firestore.collection('users').where('mobileNumber', isEqualTo: mobileNumber).limit(1).get();

      if (querySnapshot.docs.isEmpty) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'No user found for that mobile number.');
      }

      final userDoc = querySnapshot.docs.first;
      final email = userDoc.data()['email'] as String?;

      if (email == null) {
        throw Exception('User document is missing an email.');
      }

      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.message}');
      return null;
    }
  }
}