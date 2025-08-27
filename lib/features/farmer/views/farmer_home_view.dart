// lib/features/farmer/views/farmer_home_view.dart

import 'package:agritech/features/farmer/views/all_my_crops_view.dart'; // <-- ADD THIS IMPORT
import 'package:agritech/features/farmer/views/edit_profile_view.dart';
import 'package:agritech/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';

class FarmerHomeView extends StatelessWidget {
  const FarmerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: dbService.getUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text("User data not found."));
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final bool isProfileComplete = userData['profileCompleted'] ?? false;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.green,
                expandedHeight: 120.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Text(
                    "${l10n.welcome} ${userData['displayName'] ?? 'Farmer'}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (!isProfileComplete)
                          _buildProfileCompletionCard(context, l10n, userData),
                        const SizedBox(height: 16),
                        _buildSectionHeader(
                          context,
                          l10n.myListedCrops,
                          () {
                            // THIS IS THE CHANGE
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const AllMyCropsView(),
                            ));
                          },
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 220,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: dbService.getMyListedCropsStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Card(
                                  child: Center(
                                    child: Text(
                                      'You have not listed any crops yet.',
                                    ),
                                  ),
                                );
                              }

                              final crops = snapshot.data!.docs;

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: crops.length,
                                itemBuilder: (context, index) {
                                  final crop = crops[index].data()
                                      as Map<String, dynamic>;
                                  return Card(
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Container(
                                      width: 200,
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            crop['cropType'] ?? 'Unknown Crop',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          Text(crop['variant'] ?? ''),
                                          const Spacer(),
                                          Text(
                                            '${crop['initialQuantityKg']} Kg',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '৳ ${crop['pricePerKg']} per Kg',
                                          ),
                                          Chip(
                                            label: Text(
                                              crop['status'] ?? 'pending',
                                            ),
                                            backgroundColor:
                                                Colors.amber.shade200,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCompletionCard(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> userData,
  ) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              l10n.completeProfilePrompt,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditProfileView(userData: userData),
                ),
              ),
              child: Text(l10n.completeProfileButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onViewAll,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onViewAll,
          child: Text(AppLocalizations.of(context)!.viewAll),
        ),
      ],
    );
  }
}