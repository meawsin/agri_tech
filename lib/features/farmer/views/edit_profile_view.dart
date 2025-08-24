import 'dart:io';
import 'package:agritech/features/auth/widgets/language_switcher.dart';
import 'package:agritech/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/database_service.dart';

class EditProfileView extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileView({super.key, required this.userData});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  // Simplified controllers
  late final TextEditingController _farmNameController;
  late final TextEditingController _locationController;

  // Image State
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  XFile? _nidFrontImage;
  XFile? _nidBackImage;
  bool _isLoading = false;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _farmNameController = TextEditingController(
      text: widget.userData['farmName'] ?? '',
    );
    // Initialize the single location controller
    _locationController = TextEditingController(
      text: widget.userData['location'] ?? '',
    );
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(
    ImageSource source,
    Function(XFile) onImagePicked,
  ) async {
    final XFile? pickedImage = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedImage != null) {
      setState(() => onImagePicked(pickedImage));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? profileUrl = widget.userData['profileImageUrl'];
      if (_profileImage != null) {
        profileUrl = await _dbService.uploadImage(
          _profileImage!,
          'profile_images',
        );
      }
      String? nidFrontUrl = widget.userData['nidFrontImageUrl'];
      if (_nidFrontImage != null) {
        nidFrontUrl = await _dbService.uploadImage(
          _nidFrontImage!,
          'nid_images',
        );
      }
      String? nidBackUrl = widget.userData['nidBackImageUrl'];
      if (_nidBackImage != null) {
        nidBackUrl = await _dbService.uploadImage(_nidBackImage!, 'nid_images');
      }

      // Call the updated service method with the simple location string
      await _dbService.updateUserProfile(
        farmName: _farmNameController.text.trim(),
        location: _locationController.text.trim(),
        profileImageUrl: profileUrl,
        nidFrontUrl: nidFrontUrl,
        nidBackUrl: nidBackUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
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
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Farm name is required' : null,
              ),
              const SizedBox(height: 16),

              // The new, simple location field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location / Address',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your location' : null,
              ),

              const SizedBox(height: 24),
              Text(
                l10n.nidUpload,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                    _showImagePicker((img) => _nidFrontImage = img, l10n),
              ),
              const SizedBox(height: 24),
              const Text(
                'Change Language',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const LanguageSwitcher(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
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
            child:
                _profileImage == null &&
                    widget.userData['profileImageUrl'] == null
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: () =>
                  _pickImage(ImageSource.gallery, (img) => _profileImage = img),
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
