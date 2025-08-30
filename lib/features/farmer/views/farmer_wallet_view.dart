// lib/features/farmer/views/farmer_wallet_view.dart

import 'package:agritech/core/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FarmerWalletView extends StatelessWidget {
  const FarmerWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    return Scaffold(
        appBar: AppBar(title: const Text('My Wallet')),
        body: Column(
          children: [
            // Balance Card
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Current Balance',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 8),
                    // This is a placeholder value. You would fetch this from your 'wallets' collection.
                    const Text('৳ 5,250.00',
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
            const Text('Transaction History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Transaction List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: dbService.getTransactionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No transactions found.'));
                  }
                  final transactions = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction =
                          transactions[index].data() as Map<String, dynamic>;
                      final bool isCredit = transaction['amount'] >= 0;
                      return ListTile(
                        leading: Icon(
                          isCredit
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                        title: Text(transaction['type'] ?? 'Transaction'),
                        subtitle: Text(
                            'Order ID: ${transaction['relatedOrderId'] ?? 'N/A'}'),
                        trailing: Text(
                          '৳ ${transaction['amount']}',
                          style: TextStyle(
                            color: isCredit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ));
  }
}