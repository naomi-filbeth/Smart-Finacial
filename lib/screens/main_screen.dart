import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'home_screen.dart';
import 'add_sales_screen.dart';
import 'inventory_screen.dart';
import 'insights_screen.dart';
import 'profit_loss_screen.dart';
import 'debtors_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _screens => [
    const HomeScreen(),
    AddSaleScreen(
      onSaleRecorded: () {
        setState(() {
          _selectedIndex = 0;
        });
      },
    ),
    const InventoryScreen(),
    const InsightsScreen(),
    const ProfitLossScreen(),
    const DebtorsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF26A69A), // Set background color here
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color(0xFF26A69A),
        color: Colors.white,
        buttonBackgroundColor: Colors.white,
        height: 60,
        index: _selectedIndex,
        items: const [
          Icon(Icons.store, size: 30, color: Color(0xFF26A69A)),
          Icon(Icons.add_shopping_cart, size: 30, color: Color(0xFF26A69A)),
          Icon(Icons.inventory, size: 30, color: Color(0xFF26A69A)),
          Icon(Icons.insights, size: 30, color: Color(0xFF26A69A)),
          Icon(Icons.account_balance, size: 30, color: Color(0xFF26A69A)),
          Icon(Icons.people, size: 30, color: Color(0xFF26A69A)),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}