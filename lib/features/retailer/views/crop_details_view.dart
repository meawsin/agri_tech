// lib/features/retailer/views/crop_details_view.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:flutter/material.dart';

class CropDetailsView extends StatefulWidget {
  final String cropId;
  final Map<String, dynamic> cropData;

  const CropDetailsView({super.key, required this.cropId, required this.cropData});

  @override
  State<CropDetailsView> createState() => _CropDetailsViewState();
}

class _CropDetailsViewState extends State<CropDetailsView> {
  final TextEditingController _quantityController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cropData['name'] ?? 'Crop Details'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Added for smaller screens
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.cropData['name'] ?? 'Unnamed Crop',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('Sold by: ${widget.cropData['farmerName'] ?? 'Unknown Farmer'}'),
              const SizedBox(height: 16),
              Text('Price: ৳${widget.cropData['pricePerKg']}/Kg'),
              Text('Available: ${widget.cropData['quantityKg']} Kg'),
              const SizedBox(height: 24),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter quantity in Kg',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    final quantity = int.tryParse(_quantityController.text);
                    if (quantity == null || quantity <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a valid quantity.')),
                      );
                      return;
                    }
                    if (quantity > widget.cropData['quantityKg']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Requested quantity exceeds available stock.')),
                      );
                      return;
                    }

                    // Store context-dependent objects before the async gap
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    // CORRECTED: Call placeOrder with the required named parameters
                    await _dbService.placeOrder(
                      cropId: widget.cropId,
                      farmerUid: widget.cropData['farmerUid'],
                      farmerName: widget.cropData['farmerName'],
                      cropType: widget.cropData['name'], // Using name as cropType for the order
                      quantityKg: quantity.toDouble(),
                      pricePerKg: (widget.cropData['pricePerKg'] as num).toDouble(),
                    );

                    if (!mounted) return;

                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Order placed successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Place Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}