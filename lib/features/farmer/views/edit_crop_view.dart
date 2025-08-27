// lib/features/farmer/views/edit_crop_view.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:agritech/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditCropView extends StatefulWidget {
  final QueryDocumentSnapshot cropDoc;
  const EditCropView({super.key, required this.cropDoc});

  @override
  State<EditCropView> createState() => _EditCropViewState();
}

class _EditCropViewState extends State<EditCropView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cropTypeController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _variantController;
  late TextEditingController _seedBrandController;

  DateTime? _plantationDate;
  DateTime? _estimatedHarvestDate;

  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final cropData = widget.cropDoc.data() as Map<String, dynamic>;

    _cropTypeController = TextEditingController(text: cropData['cropType'] ?? '');
    _quantityController = TextEditingController(text: cropData['initialQuantityKg']?.toString() ?? '');
    _priceController = TextEditingController(text: cropData['pricePerKg']?.toString() ?? '');
    _variantController = TextEditingController(text: cropData['variant'] ?? '');
    _seedBrandController = TextEditingController(text: cropData['seedBrand'] ?? '');

    if (cropData['plantationDate'] != null) {
      _plantationDate = (cropData['plantationDate'] as Timestamp).toDate();
    }
    if (cropData['estimatedHarvestDate'] != null) {
      _estimatedHarvestDate = (cropData['estimatedHarvestDate'] as Timestamp).toDate();
    }
  }

  @override
  void dispose() {
    _cropTypeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _variantController.dispose();
    _seedBrandController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context, {required bool isPlantationDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isPlantationDate) {
          _plantationDate = picked;
        } else {
          _estimatedHarvestDate = picked;
        }
      });
    }
  }

  Future<void> _saveCrop() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool isSuccess = false;
    final l10n = AppLocalizations.of(context)!;

    try {
      await _dbService.updateCrop(
        cropId: widget.cropDoc.id,
        cropType: _cropTypeController.text.trim(),
        initialQuantityKg: double.parse(_quantityController.text.trim()),
        pricePerKg: double.parse(_priceController.text.trim()),
        variant: _variantController.text.trim(),
        seedBrand: _seedBrandController.text.trim(),
        plantationDate: _plantationDate,
        estimatedHarvestDate: _estimatedHarvestDate,
      );
      isSuccess = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToListCrop}: $e'), // You can add a new key for "Failed to update"
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Crop updated successfully!"), // Add new localization key
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
        title: Text("Edit Crop"), // Add new localization key
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
                decoration: InputDecoration(
                  labelText: l10n.cropTypeHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? l10n.cropTypeValidation : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: l10n.quantityHint,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty) ? l10n.quantityValidation : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: l10n.priceHint,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty) ? l10n.priceValidation : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _variantController,
                decoration: InputDecoration(
                  labelText: l10n.variantHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seedBrandController,
                decoration: InputDecoration(
                  labelText: l10n.seedBrandHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                context: context,
                label: l10n.plantationDateLabel,
                date: _plantationDate,
                onPressed: () => _selectDate(context, isPlantationDate: true),
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                context: context,
                label: l10n.estimatedHarvestDateLabel,
                date: _estimatedHarvestDate,
                onPressed: () => _selectDate(context, isPlantationDate: false),
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
                    : Text(
                        "Update Crop", // Add new localization key
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          date != null ? DateFormat.yMMMd().format(date) : l10n.selectDate,
        ),
      ),
    );
  }
}