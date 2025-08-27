// In lib/features/retailer/views/retailer_home_view.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:agritech/features/retailer/views/crop_details_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RetailerHomeView extends StatelessWidget {
  const RetailerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Available Crops'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // --- THIS IS THE UPDATED BODY ---
      body: StreamBuilder<QuerySnapshot>(
        stream: dbService.getAllAvailableCropsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No crops are available at the moment.'),
            );
          }

          final crops = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final cropDoc = crops[index]; // Get the full document
              final crop = cropDoc.data() as Map<String, dynamic>;
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    crop['cropType'] ?? 'Unknown Crop',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Listed by: ${crop['farmerName']}\nQuantity: ${crop['availableQuantityKg']} Kg',
                  ),
                  trailing: Text(
                    '৳ ${crop['pricePerKg']}\nper Kg',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  // 2. UPDATE THE ONTAP CALLBACK
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CropDetailsView(cropDoc: cropDoc),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      // --- END OF UPDATED BODY ---
    );
  }
}
