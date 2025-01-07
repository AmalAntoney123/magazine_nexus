import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  get context => null;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref().onValue,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return _buildLoadingDashboard();
        }

        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final users = data['users'] as Map<dynamic, dynamic>? ?? {};
        final magazines = data['magazines'] as Map<dynamic, dynamic>? ?? {};
        final subscriptions =
            data['subscriptions'] as Map<dynamic, dynamic>? ?? {};
        final issues = data['magazine_issues'] as Map<dynamic, dynamic>? ?? {};

        // Calculate statistics
        final totalUsers = users.length;
        final activeMagazines = magazines.values
            .where((magazine) => magazine['isActive'] == true)
            .length;

        int activeSubscriptions = 0;
        double totalRevenue = 0;
        double monthlyRevenue = 0;
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);

        subscriptions.forEach((userId, userSubs) {
          (userSubs as Map).forEach((subId, sub) {
            final endDate = DateTime.parse(sub['endDate']);
            if (endDate.isAfter(now) && sub['status'] == 'active') {
              activeSubscriptions++;
              final amount = (sub['amount'] as num).toDouble();
              totalRevenue += amount;

              final startDate = DateTime.parse(sub['startDate']);
              if (startDate.isAfter(monthStart)) {
                monthlyRevenue += amount;
              }
            }
          });
        });

        final totalIssues = issues.length;
        final deliveredIssues = issues.values
            .where((issue) => issue['deliveryStatus'] == 'delivered')
            .length;

        final currencyFormat = NumberFormat.currency(
          symbol: '₹',
          locale: 'en_IN',
          decimalDigits: 0,
        );

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildDashboardCard(
                      context: context,
                      title: 'Total Users',
                      value: totalUsers.toString(),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    _buildDashboardCard(
                      context: context,
                      title: 'Active Magazines',
                      value: activeMagazines.toString(),
                      icon: Icons.book,
                      color: Colors.green,
                    ),
                    _buildDashboardCard(
                      context: context,
                      title: 'Active Subscriptions',
                      value: activeSubscriptions.toString(),
                      icon: Icons.subscriptions,
                      color: Colors.orange,
                    ),
                    _buildDashboardCard(
                      context: context,
                      title: 'Monthly Revenue',
                      value: currencyFormat.format(monthlyRevenue),
                      icon: Icons.attach_money,
                      color: Colors.purple,
                    ),
                    _buildDashboardCard(
                      context: context,
                      title: 'Total Revenue',
                      value: currencyFormat.format(totalRevenue),
                      icon: Icons.account_balance_wallet,
                      color: Colors.teal,
                    ),
                    _buildDashboardCard(
                      context: context,
                      title: 'Delivery Rate',
                      value: totalIssues > 0
                          ? '${(deliveredIssues * 100 / totalIssues).round()}%'
                          : '0%',
                      icon: Icons.local_shipping,
                      color: Colors.indigo,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingDashboard() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: List.generate(
                6,
                (index) => _buildDashboardCard(
                  context: context,
                  title: '',
                  value: '',
                  icon: Icons.help,
                  color: Colors.grey,
                  isLoading: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 20,
                      width: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
