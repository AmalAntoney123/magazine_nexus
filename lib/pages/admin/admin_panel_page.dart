import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:magazine_nexus/pages/admin/tabs/dashboard_tab.dart';
import 'package:magazine_nexus/pages/admin/tabs/subscription_management_tab.dart';

import 'tabs/magazine_management_tab.dart';
import 'tabs/user_management_tab.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // List of tab titles for the AppBar
    final tabTitles = [
      'Dashboard',
      'User Management',
      'Magazine Management',
      'Subscription Management'
    ];

    return Scaffold(
      appBar: AppBar(
        // Show current tab title
        title: Text(tabTitles[_tabController.index]),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 80),
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    onTap: () {
                      _tabController.animateTo(0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('User Management'),
                    onTap: () {
                      _tabController.animateTo(1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('Magazine Management'),
                    onTap: () {
                      _tabController.animateTo(2);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.subscriptions),
                    title: const Text('Subscription Management'),
                    onTap: () {
                      _tabController.animateTo(3);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            // Logout button at bottom of drawer
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardTab(),
          UserManagementTab(),
          MagazineManagementTab(),
          SubscriptionManagementTab(),
        ],
      ),
    );
  }
}
