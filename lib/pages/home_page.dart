import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

import '../services/firebase_auth_service.dart';
import 'home_tabs/discover_page.dart';
import 'home_tabs/subscriptions_page.dart';
import 'home_tabs/cart_page.dart';
import 'home_tabs/library_page.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  int _activeIndex = 0;

  final List<IconData> _iconList = [
    Icons.explore,
    Icons.subscriptions,
    Icons.shopping_cart,
    Icons.library_books,
  ];

  final List<String> _tabLabels = [
    'Discover',
    'Subscriptions',
    'Cart',
    'Library',
  ];

  void _handleLogout(BuildContext context) async {
    try {
      await _authService.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabLabels[_activeIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: _iconList,
        activeIndex: _activeIndex,
        gapLocation: GapLocation.none,
        activeColor: Theme.of(context).colorScheme.primary,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
        height: 65,
        onTap: (index) => setState(() => _activeIndex = index),
        splashColor: Theme.of(context).colorScheme.primary,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildBody() {
    switch (_activeIndex) {
      case 0:
        return const DiscoverPage();
      case 1:
        return const SubscriptionsPage();
      case 2:
        return const CartPage();
      case 3:
        return const LibraryPage();
      default:
        return const DiscoverPage();
    }
  }
}
