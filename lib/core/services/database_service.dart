import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> uploadImage(XFile image, String path) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final ref = _storage.ref(path).child('${user.uid}-${DateTime.now().toIso8601String()}');
      final uploadTask = await ref.putFile(File(image.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image Upload Error: $e');
      return null;
    }
  }

  // UPDATED FUNCTION: 'location' is now a simple String
  Future<void> updateUserProfile({
    required String farmName,
    required String location, // Changed back to String
    String? profileImageUrl,
    String? nidFrontUrl,
    String? nidBackUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'farmName': farmName,
      'location': location, // Saves the simple string
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (nidFrontUrl != null) 'nidFrontImageUrl': nidFrontUrl,
      if (nidBackUrl != null) 'nidBackImageUrl': nidBackUrl,
      'profileCompleted': true,
      'nidStatus': (nidFrontUrl != null || nidBackUrl != null) ? 'pending' : 'not_submitted',
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }
    return _firestore.collection('users').doc(user.uid).snapshots();
  }
}