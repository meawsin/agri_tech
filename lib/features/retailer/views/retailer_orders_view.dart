// lib/features/retailer/views/retailer_orders_view.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:agritech/features/retailer/widgets/rating_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RetailerOrdersView extends StatelessWidget {
  const RetailerOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dbService.getRetailerOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have not placed any orders yet.'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final bool isDelivered = order['orderStatus'] == 'Delivered';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(order['cropName'] ?? 'Unknown Crop'),
                  subtitle: Text(
                      'Quantity: ${order['quantityKg']} Kg\nFrom: ${order['farmerName']}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Status: ${order['orderStatus']}'),
                      if (isDelivered)
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => RatingDialog(
                                orderId: orderId,
                                farmerId: order['farmerUid'],
                              ),
                            );
                          },
                          child: const Text('Rate Farmer'),
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
}