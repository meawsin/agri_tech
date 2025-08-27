// lib/features/farmer/views/add_crop_view.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:agritech/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AddCropView extends StatefulWidget {
  const AddCropView({super.key});

  @override
  State<AddCropView> createState() => _AddCropViewState();
}

class _AddCropViewState extends State<AddCropView> {
  final _formKey = GlobalKey<FormState>();
  final _cropTypeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  // Optional controllers for more detail
  final _variantController = TextEditingController();
  final _seedBrandController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _cropTypeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _variantController.dispose();
    _seedBrandController.dispose();
    super.dispose();
  }

  Future<void> _saveCrop() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Use a boolean to track success
    bool isSuccess = false;

    try {
      final double initialQuantity = double.parse(
        _quantityController.text.trim(),
      );
      final double pricePerKg = double.parse(_priceController.text.trim());

      await _dbService.addCrop(
        cropType: _cropTypeController.text.trim(),
        initialQuantityKg: initialQuantity,
        pricePerKg: pricePerKg,
        variant: _variantController.text.trim(),
        seedBrand: _seedBrandController.text.trim(),
      );

      // Set the flag to true ONLY if the await call completes without error
      isSuccess = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to list crop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        // Only show success and pop the screen if the operation was successful
        if (isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Crop listed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('List a New Crop'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _cropTypeController,
                decoration: const InputDecoration(
                  labelText: 'Crop Type (e.g., Tomato, Potato)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a crop type'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Expected Total Quantity (in Kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a quantity'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price per Kg (in BDT)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a price'
                    : null,
              ),
              const SizedBox(height: 24),
              // Optional fields from your PDF
              TextFormField(
                controller: _variantController,
                decoration: const InputDecoration(
                  labelText: 'Variant (Optional, e.g., Roma)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seedBrandController,
                decoration: const InputDecoration(
                  labelText: 'Seed Brand (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCrop,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'List This Crop',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
