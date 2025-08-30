// lib/features/farmer/views/my_orders_view.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:agritech/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyOrdersView extends StatelessWidget {
  const MyOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myOrdersTitle),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dbService.getMyOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(l10n.noOrdersYet));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final bool canBeActioned = order['orderStatus'] == 'placed';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(order['cropName'] ?? 'Unknown Crop'),
                        subtitle: Text(
                            '${l10n.quantityLabel}: ${order['quantityKg']} Kg\n${l10n.fromLabel}: ${order['retailerName']}'),
                        trailing:
                            Text('${l10n.statusLabel}: ${order['orderStatus']}'),
                      ),
                      if (canBeActioned)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  dbService.updateOrderStatus(orderId, 'Cancelled'),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => dbService.updateOrderStatus(
                                  orderId, 'Confirmed'),
                              child: const Text('Confirm'),
                            ),
                          ],
                        )
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