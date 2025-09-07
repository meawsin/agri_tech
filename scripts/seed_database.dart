// scripts/seed_database.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import 'dart:math';
import '../lib/firebase_options.dart'; // Import your project's Firebase options

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final faker = Faker();
  final random = Random();

  print('Starting database seeding...');

  // --- Seed Users ---
  final List<String> userIds = [];
  final List<String> farmerIds = [];
  final List<String> retailerIds = [];

  print('Seeding 50 users...');
  for (int i = 0; i < 50; i++) {
    final role = random.nextBool() ? 'farmer' : 'retailer';
    final userRef = firestore.collection('users').doc();
    await userRef.set({
      'displayName': faker.person.name(),
      'email': faker.internet.email(),
      'role': role,
      'createdAt': Timestamp.now(),
    });
    userIds.add(userRef.id);
    if (role == 'farmer') {
      farmerIds.add(userRef.id);
    } else {
      retailerIds.add(userRef.id);
    }
  }

  // --- Seed Crops ---
  final List<String> cropIds = [];
  final cropTypes = ['Potato', 'Tomato', 'Onion', 'Rice', 'Wheat', 'Jute'];

  print('Seeding 100 crops...');
  for (int i = 0; i < 100; i++) {
    final cropRef = firestore.collection('crops').doc();
    await cropRef.set({
      'cropType': cropTypes[random.nextInt(cropTypes.length)],
      'farmerUid': farmerIds[random.nextInt(farmerIds.length)],
      'quantity': random.nextInt(200) + 50,
      'unit': 'kg',
      'price': (random.nextDouble() * 50 + 20).round(),
      'qcStatus': 'approved', // Assume most are approved
      'listedDate': Timestamp.now(),
    });
    cropIds.add(cropRef.id);
  }

  // --- Seed Orders ---
  print('Seeding 200 orders...');
  final orderStatuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
  for (int i = 0; i < 200; i++) {
    final orderRef = firestore.collection('orders').doc();
    final quantity = random.nextInt(50) + 10;
    final price = (random.nextDouble() * 50 + 20).round();
    await orderRef.set({
      'farmerUid': farmerIds[random.nextInt(farmerIds.length)],
      'retailerUid': retailerIds[random.nextInt(retailerIds.length)],
      'cropId': cropIds[random.nextInt(cropIds.length)],
      'cropName': cropTypes[random.nextInt(cropTypes.length)],
      'quantity': quantity,
      'unit': 'kg',
      'totalPrice': quantity * price,
      'orderStatus': orderStatuses[random.nextInt(orderStatuses.length)],
      'paymentStatus': 'pending',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: random.nextInt(30)))),
    });
  }

  print('✅ Database seeding complete!');
}