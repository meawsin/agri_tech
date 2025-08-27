// lib/features/retailer/views/crop_details_view.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CropDetailsView extends StatelessWidget {
  final QueryDocumentSnapshot cropDoc;

  const CropDetailsView({super.key, required this.cropDoc});


  void _showPlaceOrderDialog(BuildContext context, Map<String, dynamic> crop) {
    final quantityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Place an Order'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter quantity in Kg',
                hintText: 'e.g., 50',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quantity';
                }
                final quantity = double.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return 'Please enter a valid quantity';
                }
                if (quantity > crop['availableQuantityKg']) {
                  return 'Quantity exceeds available stock';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Confirm Order'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final quantity = double.parse(quantityController.text.trim());
                  final dbService = DatabaseService();

                  try {
                    await dbService.placeOrder(
                      cropId: cropDoc.id,
                      farmerUid: crop['farmerUid'],
                      farmerName: crop['farmerName'],
                      cropType: crop['cropType'],
                      quantityKg: quantity,
                      pricePerKg: crop['pricePerKg'].toDouble(),
                    );
                    Navigator.of(context).pop(); // Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                     Navigator.of(context).pop(); // Close the dialog
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final crop = cropDoc.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(crop['cropType'] ?? 'Crop Details'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              crop['cropType'] ?? 'Unknown Crop',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (crop['variant'] != null && crop['variant'].isNotEmpty)
              Text(
                'Variant: ${crop['variant']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow('Price', '৳ ${crop['pricePerKg']} / Kg'),
                    _buildDetailRow('Available Quantity', '${crop['availableQuantityKg']} Kg'),
                    _buildDetailRow('Listed by', crop['farmerName'] ?? 'N/A'),
                    _buildDetailRow('Farm Location', crop['farmerLocation'] ?? 'Not Available'),
                    if (crop['seedBrand'] != null && crop['seedBrand'].isNotEmpty)
                      _buildDetailRow('Seed Brand', crop['seedBrand']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Place Order'),
                onPressed: () => _showPlaceOrderDialog(context, crop),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}