// lib/features/farmer/views/edit_profile_view.dart

import 'dart:io';
import 'package:agritech/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agritech/core/services/location_service.dart';
import '../../../core/services/database_service.dart';

class EditProfileView extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileView({super.key, required this.userData});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _farmNameController;
  late final TextEditingController _villageController;

  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  XFile? _nidFrontImage;
  XFile? _nidBackImage;
  bool _isLoading = false;
  final DatabaseService _dbService = DatabaseService();
  final LocationService _locationService = LocationService();

  List<String> _divisions = [];
  List<String> _districts = [];
  List<String> _upazilas = [];
  List<String> _unions = [];

  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedUpazila;
  String? _selectedUnion;

  @override
  void initState() {
    super.initState();
    _farmNameController =
        TextEditingController(text: widget.userData['farmName'] ?? '');
    _villageController =
        TextEditingController(text: widget.userData['location']?['village'] ?? '');
    
    // Initialize and load the address data safely.
    _initializeAddressFields();
  }

  Future<void> _initializeAddressFields() async {
    final locationData = widget.userData['location'] as Map<String, dynamic>? ?? {};

    // Load all divisions first.
    _divisions = await _locationService.getDivisions();

    // Check if the saved division is valid before setting it.
    String? initialDivision = locationData['division'];
    if (initialDivision != null && _divisions.contains(initialDivision)) {
      _selectedDivision = initialDivision;
      _districts = await _locationService.getDistricts(_selectedDivision!);
      
      // Check if the saved district is valid.
      String? initialDistrict = locationData['district'];
      if(initialDistrict != null && _districts.contains(initialDistrict)) {
        _selectedDistrict = initialDistrict;
        _upazilas = await _locationService.getUpazilas(_selectedDivision!, _selectedDistrict!);

        // Check if the saved upazila is valid.
        String? initialUpazila = locationData['upazila'];
        if(initialUpazila != null && _upazilas.contains(initialUpazila)) {
          _selectedUpazila = initialUpazila;
          _unions = await _locationService.getUnions(_selectedDivision!, _selectedDistrict!, _selectedUpazila!);

          // Check if the saved union is valid.
          String? initialUnion = locationData['union'];
          if(initialUnion != null && _unions.contains(initialUnion)) {
            _selectedUnion = initialUnion;
          }
        }
      }
    }
    // Update the UI once all data is loaded and validated.
    if(mounted) setState(() {});
  }


  @override
  void dispose() {
    _farmNameController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(
      ImageSource source, Function(XFile) onImagePicked) async {
    final XFile? pickedImage =
        await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedImage != null && mounted) {
      setState(() => onImagePicked(pickedImage));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      String? profileUrl = widget.userData['profileImageUrl'];
      if (_profileImage != null) {
        profileUrl =
            await _dbService.uploadImage(_profileImage!, 'profile_images');
      }
      String? nidFrontUrl = widget.userData['nidFrontImageUrl'];
      if (_nidFrontImage != null) {
        nidFrontUrl =
            await _dbService.uploadImage(_nidFrontImage!, 'nid_images');
      }
      String? nidBackUrl = widget.userData['nidBackImageUrl'];
      if (_nidBackImage != null) {
        nidBackUrl =
            await _dbService.uploadImage(_nidBackImage!, 'nid_images');
      }

      final locationMap = {
        'division': _selectedDivision ?? '',
        'district': _selectedDistrict ?? '',
        'upazila': _selectedUpazila ?? '',
        'union': _selectedUnion ?? '',
        'village': _villageController.text.trim(),
      };

      await _dbService.updateUserProfile(
        farmName: _farmNameController.text.trim(),
        location: locationMap,
        profileImageUrl: profileUrl,
        nidFrontUrl: nidFrontUrl,
        nidBackUrl: nidBackUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.updateSuccess),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${l10n.updateFailed}: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileImagePicker(l10n),
              const SizedBox(height: 24),
              TextFormField(
                controller: _farmNameController,
                decoration: InputDecoration(
                    labelText: l10n.farmName,
                    border: const OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              // Division Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDivision,
                items: _divisions.map((String division) {
                  return DropdownMenuItem<String>(
                      value: division, child: Text(division));
                }).toList(),
                onChanged: (newValue) async {
                  setState(() {
                    _selectedDivision = newValue;
                    _selectedDistrict = null;
                    _districts = [];
                    _selectedUpazila = null;
                    _upazilas = [];
                    _selectedUnion = null;
                    _unions = [];
                  });
                  if (newValue != null) {
                    _districts = await _locationService.getDistricts(newValue);
                    setState(() {});
                  }
                },
                decoration: InputDecoration(
                    labelText: l10n.division,
                    border: const OutlineInputBorder()),
                validator: (v) => v == null ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),

              // District Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                items: _districts.map((String district) {
                  return DropdownMenuItem<String>(
                      value: district, child: Text(district));
                }).toList(),
                onChanged: (newValue) async {
                  setState(() {
                    _selectedDistrict = newValue;
                    _selectedUpazila = null;
                    _upazilas = [];
                    _selectedUnion = null;
                    _unions = [];
                  });
                  if (newValue != null) {
                    _upazilas = await _locationService.getUpazilas(_selectedDivision!, newValue);
                     setState(() {});
                  }
                },
                decoration: InputDecoration(
                    labelText: l10n.district,
                    border: const OutlineInputBorder()),
                validator: (v) => v == null ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),

              // Upazila Dropdown
              DropdownButtonFormField<String>(
                  value: _selectedUpazila,
                  items: _upazilas.map((String upazila) {
                    return DropdownMenuItem<String>(
                        value: upazila, child: Text(upazila));
                  }).toList(),
                  onChanged: (newValue) async {
                    setState(() {
                      _selectedUpazila = newValue;
                      _selectedUnion = null;
                      _unions = [];
                    });
                    if (newValue != null) {
                      _unions = await _locationService.getUnions(_selectedDivision!, _selectedDistrict!, newValue);
                      setState(() {});
                    }
                  },
                  decoration: InputDecoration(
                      labelText: l10n.upazilaThana,
                      border: const OutlineInputBorder()),
                  validator: (v) => v == null ? l10n.requiredField : null),
              const SizedBox(height: 16),

              // Union Dropdown
              DropdownButtonFormField<String>(
                  value: _selectedUnion,
                  items: _unions.map((String union) {
                    return DropdownMenuItem<String>(
                        value: union, child: Text(union));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedUnion = newValue;
                    });
                  },
                  decoration: InputDecoration(
                      labelText: "Union", // Consider adding this to l10n
                      border: const OutlineInputBorder()),
                  validator: (v) => v == null ? l10n.requiredField : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _villageController,
                decoration: InputDecoration(
                    labelText: l10n.villageArea,
                    border: const OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? l10n.requiredField : null,
              ),
              const SizedBox(height: 24),
              Text(l10n.nidUpload,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildImagePicker(
                title: l10n.nidFront,
                imageFile: _nidFrontImage,
                existingImageUrl: widget.userData['nidFrontImageUrl'],
                onTap: () =>
                    _showImagePicker((img) => _nidFrontImage = img, l10n),
              ),
              const SizedBox(height: 16),
              _buildImagePicker(
                title: l10n.nidBack,
                imageFile: _nidBackImage,
                existingImageUrl: widget.userData['nidBackImageUrl'],
                onTap: () =>
                    _showImagePicker((img) => _nidBackImage = img, l10n),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(l10n.saveProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePicker(Function(XFile) onImagePicked, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.gallery),
              onTap: () {
                _pickImage(ImageSource.gallery, onImagePicked);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l10n.camera),
              onTap: () {
                _pickImage(ImageSource.camera, onImagePicked);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker(AppLocalizations l10n) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _profileImage != null
                ? FileImage(File(_profileImage!.path))
                : (widget.userData['profileImageUrl'] != null
                        ? NetworkImage(widget.userData['profileImageUrl'])
                        : null)
                    as ImageProvider?,
            child: _profileImage == null &&
                    widget.userData['profileImageUrl'] == null
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: () => _showImagePicker(
                  (img) => setState(() => _profileImage = img), l10n),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.green,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker({
    required String title,
    XFile? imageFile,
    String? existingImageUrl,
    required VoidCallback onTap,
  }) {
    Widget imageWidget;
    if (imageFile != null) {
      imageWidget = Image.file(
        File(imageFile.path),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
      imageWidget = Image.network(
        existingImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else {
      imageWidget = const Icon(Icons.add_a_photo, size: 40, color: Colors.grey);
    }
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: imageWidget,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}