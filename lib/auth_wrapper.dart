import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'features/farmer/views/farmer_main_screen.dart';
import 'features/auth/views/login_view.dart';
import 'features/retailer/views/retailer_home_view.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Show a loading screen while checking auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // If user is logged out, show LoginView
        if (!authSnapshot.hasData) {
          return const LoginView();
        }

        // If user is logged in, check their role in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(authSnapshot.data!.uid).get(),
          builder: (context, userSnapshot) {
            // While waiting for user data, show a loading screen
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // If there's an error fetching user data
            if (userSnapshot.hasError) {
              return const Scaffold(body: Center(child: Text('Error fetching user data.')));
            }

            // If user data doesn't exist
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Scaffold(body: Center(child: Text('User not found in database.')));
            }

            // Get the role from the document
            final userRole = userSnapshot.data!.get('role');

            // Show the correct dashboard based on the role
            if (userRole == 'farmer') {
              return const FarmerMainScreen();
            } else if (userRole == 'retailer') {
              return const RetailerHomeView();
            } else {
              // Fallback for any other roles or issues
              return const Scaffold(body: Center(child: Text('Unknown role.')));
            }
          },
        );
      },
    );
  }
}