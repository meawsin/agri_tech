import 'package:agritech/features/farmer/views/farmer_home_view.dart';
import 'package:agritech/features/farmer/views/add_crop_view.dart';
import 'package:agritech/features/farmer/views/farmer_profile_view.dart';
import 'package:agritech/features/farmer/views/farmer_wallet_view.dart';
import 'package:agritech/features/farmer/views/my_orders_view.dart';
import 'package:agritech/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FarmerMainScreen extends StatefulWidget {
  const FarmerMainScreen({super.key});

  @override
  State<FarmerMainScreen> createState() => _FarmerMainScreenState();
}

class _FarmerMainScreenState extends State<FarmerMainScreen> {
  int _selectedIndex = 0;

  // Final list of pages for the farmer's navigation
  static final List<Widget> _widgetOptions = <Widget>[
    const FarmerHomeView(),
    const MyOrdersView(),
    const FarmerWalletView(),
    const FarmerProfileView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              tooltip: l10n.home,
              icon: Icon(
                Icons.home,
                color: _selectedIndex == 0 ? Colors.green : Colors.grey,
              ),
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              tooltip: l10n.myOrdersTitle,
              icon: Icon(
                Icons.list_alt,
                color: _selectedIndex == 1 ? Colors.green : Colors.grey,
              ),
              onPressed: () => _onItemTapped(1),
            ),
            const SizedBox(width: 40), // The space for the FAB
            IconButton(
              tooltip: l10n.wallet,
              icon: Icon(
                Icons.account_balance_wallet, // A more descriptive icon
                color: _selectedIndex == 2 ? Colors.green : Colors.grey,
              ),
              onPressed: () => _onItemTapped(2),
            ),
            IconButton(
              tooltip: l10n.profile,
              icon: Icon(
                Icons.person,
                color: _selectedIndex == 3 ? Colors.green : Colors.grey,
              ),
              onPressed: () => _onItemTapped(3),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const AddCropView()));
        },
        backgroundColor: Colors.green,
        tooltip: l10n.addCropTitle,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}