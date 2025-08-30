// lib/features/retailer/views/retailer_home_view.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:agritech/features/retailer/views/crop_details_view.dart';
import 'package:agritech/features/retailer/views/retailer_orders_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- CORRECTED IMPORT
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
            icon: const Icon(Icons.list_alt),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const RetailerOrdersView(),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dbService.getAllCropsStream(), // <-- CORRECTED METHOD CALL
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No crops available at the moment.'));
          }

          final crops = snapshot.data!.docs;

          return ListView.builder(
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final crop = crops[index].data() as Map<String, dynamic>;
              final cropId = crops[index].id;
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(crop['name'] ?? 'Unnamed Crop'),
                  subtitle: Text(
                      'Price: ৳${crop['pricePerKg']}/Kg\nAvailable: ${crop['quantityKg']} Kg'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CropDetailsView( // <-- CORRECTED CALL
                          cropId: cropId,
                          cropData: crop,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}