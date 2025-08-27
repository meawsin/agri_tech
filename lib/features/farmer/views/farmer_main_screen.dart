import 'package:agritech/features/farmer/views/farmer_home_view.dart';
import 'package:agritech/features/farmer/views/add_crop_view.dart';
import 'package:agritech/features/farmer/views/farmer_profile_view.dart';
import 'package:agritech/features/farmer/views/farmer_wallet_view.dart';
import 'package:flutter/material.dart';

class FarmerMainScreen extends StatefulWidget {
  const FarmerMainScreen({super.key});

  @override
  State<FarmerMainScreen> createState() => _FarmerMainScreenState();
}

class _FarmerMainScreenState extends State<FarmerMainScreen> {
  int _selectedIndex = 0;

  // UPDATE THE LIST OF PAGES
  static final List<Widget> _widgetOptions = <Widget>[
    const FarmerHomeView(),
    const Center(child: Text('My Crops Page (TBD)')),
    const FarmerWalletView(), // Use the real wallet view
    const FarmerProfileView(), // Use the real profile view
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.home,
                color: _selectedIndex == 0 ? Colors.green : Colors.grey,
              ),
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              icon: Icon(
                Icons.list_alt,
                color: _selectedIndex == 1 ? Colors.green : Colors.grey,
              ),
              onPressed: () => _onItemTapped(1),
            ),
            const SizedBox(width: 40), // The space for the FAB
            IconButton(
              icon: Icon(
                Icons.wallet,
                color: _selectedIndex == 2 ? Colors.green : Colors.grey,
              ),
              onPressed: () => _onItemTapped(2),
            ),
            IconButton(
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
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
