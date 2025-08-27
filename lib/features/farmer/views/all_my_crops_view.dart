// lib/features/farmer/views/all_my_crops_view.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:agritech/features/farmer/views/edit_crop_view.dart'; // <-- ADD THIS IMPORT
import 'package:agritech/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AllMyCropsView extends StatelessWidget {
  const AllMyCropsView({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myListedCrops),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dbService.getMyListedCropsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(l10n.noOrdersYet));
          }

          final crops = snapshot.data!.docs;

          return ListView.builder(
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final cropDoc = crops[index]; // Get the full document
              final crop = cropDoc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop['cropType'] ?? 'Unknown Crop',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(l10n.quantityLabel, '${crop['initialQuantityKg']} Kg'),
                      _buildDetailRow(l10n.pricePerKg, '৳ ${crop['pricePerKg']}'),
                      _buildDetailRow(l10n.statusLabel, crop['status'] ?? 'N/A'),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.edit),
                          label: Text(l10n.editProfile),
                          onPressed: () {
                            // THIS IS THE CHANGE
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => EditCropView(cropDoc: cropDoc),
                            ));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}