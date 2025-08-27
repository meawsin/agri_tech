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
      final ref = _storage
          .ref(path)
          .child('${user.uid}-${DateTime.now().toIso8601String()}');
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
      'nidStatus': (nidFrontUrl != null || nidBackUrl != null)
          ? 'pending'
          : 'not_submitted',
    }, SetOptions(merge: true));
  }

  Future<void> addCrop({
    required String cropType,
    required double initialQuantityKg,
    required double pricePerKg,
    String? variant,
    String? seedBrand,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

     // Fetch the farmer's name AND location for denormalization
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final farmerName = userData['displayName'] ?? 'Unknown Farmer';
    final farmerLocation = userData['location'] ?? 'Not Specified';

    // Create a reference to a new document with a unique ID
    final cropRef = _firestore.collection('crops').doc();

   await cropRef.set({
      'cropId': cropRef.id,
      'farmerUid': user.uid,
      'farmerName': farmerName,
      'farmerLocation': farmerLocation, // <-- ADD THIS FIELD
      'cropType': cropType,
      'initialQuantityKg': initialQuantityKg,
      'availableQuantityKg': initialQuantityKg,
      'pricePerKg': pricePerKg,
      'variant': variant,
      'seedBrand': seedBrand,
      'plantationDate': Timestamp.now(),
      'status': 'growing',
      'qcStatus': 'pending',
      'photos': [],
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> placeOrder({
    required String cropId,
    required String farmerUid,
    required String farmerName,
    required String cropType,
    required double quantityKg,
    required double pricePerKg,
  }) async {
    final retailer = _auth.currentUser;
    if (retailer == null) return;

    final retailerDoc = await _firestore.collection('users').doc(retailer.uid).get();
    final retailerName = retailerDoc.data()?['displayName'] ?? 'Unknown Retailer';

    final orderRef = _firestore.collection('orders').doc();
    final cropRef = _firestore.collection('crops').doc(cropId);

    final double totalPrice = quantityKg * pricePerKg;

    // Use a transaction to ensure data consistency
    await _firestore.runTransaction((transaction) async {
      final cropSnapshot = await transaction.get(cropRef);
      if (!cropSnapshot.exists) {
        throw Exception("Crop does not exist!");
      }

      final double availableQuantity = cropSnapshot.data()!['availableQuantityKg'];
      if (availableQuantity < quantityKg) {
        throw Exception("Not enough quantity available.");
      }

      // Update the crop's available quantity
      transaction.update(cropRef, {
        'availableQuantityKg': availableQuantity - quantityKg,
      });

      // Create the new order document
      transaction.set(orderRef, {
        'orderId': orderRef.id,
        'cropId': cropId,
        'farmerUid': farmerUid,
        'retailerUid': retailer.uid,
        'quantityKg': quantityKg,
        'totalPrice': totalPrice,
        'orderStatus': 'placed',
        'paymentStatus': 'pending',
        'createdAt': Timestamp.now(),
        // Denormalized data for easy display
        'cropName': cropType,
        'farmerName': farmerName,
        'retailerName': retailerName,
      });
    });
  }


  // Stream for the farmer to see ONLY their own crops
  Stream<QuerySnapshot> getMyListedCropsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }
    return _firestore
        .collection('crops')
        .where('farmerUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Stream for the retailer to see ALL available crops
  Stream<QuerySnapshot> getAllAvailableCropsStream() {
    return _firestore
        .collection('crops')
        .where('status', isEqualTo: 'growing') // Or 'available'
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }
    return _firestore.collection('users').doc(user.uid).snapshots();
  }
}
