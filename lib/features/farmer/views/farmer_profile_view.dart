// lib/features/farmer/views/farmer_profile_view.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:agritech/features/farmer/views/edit_profile_view.dart';
import 'package:agritech/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class FarmerProfileView extends StatelessWidget {
  const FarmerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<DocumentSnapshot>(
      stream: dbService.getUserProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              appBar: AppBar(title: Text(l10n.myProfile), backgroundColor: Colors.white),
              body: const Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return Scaffold(
              appBar: AppBar(title: Text(l10n.myProfile), backgroundColor: Colors.white),
              body: Center(child: Text("User data not found.")));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        
        // --- THIS IS THE FIX ---
        String displayLocation = l10n.notSet;
        final locationData = userData['location'];

        if (locationData is Map<String, dynamic>) {
          // Handles the new, detailed format
          displayLocation = [
            locationData['village'],
            locationData['upazila'],
            locationData['district'],
            locationData['division']
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        } else if (locationData is String && locationData.isNotEmpty) {
          // Handles the old, simple string format
          displayLocation = locationData;
        }
        // --- END OF FIX ---


        // Calculate Profile Completeness
        int completedFields = 0;
        if (userData['displayName'] != null && (userData['displayName'] as String).isNotEmpty) completedFields++;
        if (userData['profileImageUrl'] != null) completedFields++;
        if (userData['farmName'] != null && (userData['farmName'] as String).isNotEmpty) completedFields++;
        if (locationData != null) completedFields++; // Simplified check
        if (userData['nidFrontImageUrl'] != null) completedFields++;
        if (userData['nidBackImageUrl'] != null) completedFields++;
        double completeness = completedFields / 6.0;
        if (completeness > 1.0) completeness = 1.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.myProfile),
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(context, userData, completeness, l10n),
              const SizedBox(height: 24),
              _buildDetailCard(
                context,
                title: l10n.personalInformation,
                details: {
                  l10n.name: userData['displayName'] ?? l10n.notSet,
                  l10n.email: userData['email'] ?? l10n.notSet,
                  l10n.mobile: userData['mobileNumber'] ?? l10n.notSet,
                },
              ),
              const SizedBox(height: 16),
              _buildDetailCard(
                context,
                title: l10n.farmInformation,
                details: {
                  l10n.farmName: userData['farmName'] ?? l10n.notSet,
                  l10n.location: displayLocation.isNotEmpty ? displayLocation : l10n.notSet,
                },
              ),
              const SizedBox(height: 16),
              _buildNidCard(context, l10n, userData),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => EditProfileView(userData: userData),
                  ));
                },
                icon: const Icon(Icons.edit),
                label: Text(l10n.editProfile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Helper Widgets --- (These remain mostly the same, just updating text)
  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> userData, double completeness, AppLocalizations l10n) {
     return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: userData['profileImageUrl'] != null ? NetworkImage(userData['profileImageUrl']) : null,
              child: userData['profileImageUrl'] == null ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 16),
            Text(userData['displayName'] ?? l10n.farmer, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(l10n.profileCompleteness, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              percent: completeness,
              lineHeight: 20,
              center: Text('${(completeness * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              progressColor: Colors.green,
              backgroundColor: Colors.grey.shade300,
              barRadius: const Radius.circular(10),
            ),
          ],
        ),
      ),
    );
  }
      
  Widget _buildDetailCard(BuildContext context, {required String title, required Map<String, String> details}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            ...details.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(entry.value)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNidCard(BuildContext context, AppLocalizations l10n, Map<String, dynamic> userData) {
    final String status = userData['nidStatus'] ?? 'not_submitted';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.nidUpload, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Row(
              children: [
                Text('${l10n.nidStatus} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(status.toUpperCase()),
                  backgroundColor: status == 'pending' ? Colors.orange.shade100 : (status == 'verified' ? Colors.green.shade100 : Colors.grey.shade200),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNidThumbnail(l10n.nidFront, userData['nidFrontImageUrl']),
                _buildNidThumbnail(l10n.nidBack, userData['nidBackImageUrl']),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNidThumbnail(String title, String? imageUrl) {
    return Column(
      children: [
        Text(title),
        const SizedBox(height: 8),
        Container(
          height: 100,
          width: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl != null 
            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, fit: BoxFit.cover))
            : const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
        ),
      ],
    );
  }
}