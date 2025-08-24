import 'package:flutter/material.dart';
class FarmerWalletView extends StatelessWidget {
  const FarmerWalletView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('My Wallet')), body: const Center(child: Text('Wallet Page')));
  }
}