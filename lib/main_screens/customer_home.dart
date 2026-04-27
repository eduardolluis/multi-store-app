import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/main_screens/cart.dart';
import 'package:multi_store_app/main_screens/category.dart';
import 'package:multi_store_app/main_screens/home.dart';
import 'package:multi_store_app/main_screens/profile.dart';
import 'package:multi_store_app/main_screens/stores.dart';
import 'package:badges/badges.dart' as badge;
import 'package:multi_store_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  // FIX: no usar currentUser! directamente en la lista — puede ser null
  // en casos extremos de re-renders. Usamos getter seguro.
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    // FIX: construir los tabs en build() para acceder a context y uid de forma segura
    final tabs = [
      const HomeScreen(),
      const CategoryScreen(),
      const StoresScreen(),
      const CartScreen(),
      ProfileScreen(documentId: _uid),
    ];

    return Scaffold(
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        selectedItemColor: Colors.black,
        currentIndex: _selectedIndex,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Category'),
          const BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Stores'),
          BottomNavigationBarItem(
            icon: badge.Badge(
              showBadge: context.watch<Cart>().getItems.isEmpty ? false : true,
              badgeStyle: const badge.BadgeStyle(badgeColor: Colors.yellow),
              badgeContent: Text(
                context.watch<Cart>().getItems.length.toString(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}