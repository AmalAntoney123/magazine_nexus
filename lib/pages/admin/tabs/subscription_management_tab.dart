import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SubscriptionData {
  final String id;
  final String userId;
  final String userName;
  final String magazineTitle;
  final String period;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  SubscriptionData({
    required this.id,
    required this.userId,
    required this.userName,
    required this.magazineTitle,
    required this.period,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.status,
  });
}

class SubscriptionManagementTab extends StatefulWidget {
  const SubscriptionManagementTab({super.key});

  @override
  State<SubscriptionManagementTab> createState() =>
      _SubscriptionManagementTabState();
}

class _SubscriptionManagementTabState extends State<SubscriptionManagementTab> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  List<SubscriptionData> _subscriptions = [];
  int activeSubscriptions = 0;
  double monthlyRevenue = 0.0;
  double totalRevenue = 0.0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref().child('subscriptions').onValue,
      builder: (context, AsyncSnapshot subscriptionsSnapshot) {
        if (subscriptionsSnapshot.hasError) {
          return Center(child: Text('Error: ${subscriptionsSnapshot.error}'));
        }

        if (subscriptionsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder(
          stream: FirebaseDatabase.instance.ref().child('users').onValue,
          builder: (context, AsyncSnapshot usersSnapshot) {
            if (usersSnapshot.hasError) {
              return Center(child: Text('Error: ${usersSnapshot.error}'));
            }

            if (usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!subscriptionsSnapshot.hasData || !usersSnapshot.hasData) {
              return const Center(child: Text('No data available'));
            }

            // Process subscriptions and users data
            Map<dynamic, dynamic> userSubscriptions =
                subscriptionsSnapshot.data!.snapshot!.value as Map? ?? {};
            Map<dynamic, dynamic> users =
                usersSnapshot.data!.snapshot!.value as Map? ?? {};

            _processData(userSubscriptions, users);

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stats Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Active Subscriptions',
                          activeSubscriptions.toString(),
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Monthly Revenue',
                          '₹${monthlyRevenue.toStringAsFixed(2)}',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Revenue',
                          '₹${totalRevenue.toStringAsFixed(2)}',
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // DataTable Card
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.black26,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.subscriptions,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Subscription Details',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Table Content
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      cardColor: Colors.white,
                                      dividerColor: Colors.grey[200],
                                    ),
                                    child: DataTable(
                                      sortColumnIndex: _sortColumnIndex,
                                      sortAscending: _sortAscending,
                                      columns: [
                                        DataColumn(
                                          label: const Text('User'),
                                          onSort: (columnIndex, ascending) =>
                                              _sort(columnIndex, ascending,
                                                  (d) => d.userName),
                                        ),
                                        DataColumn(
                                          label: const Text('Magazine'),
                                          onSort: (columnIndex, ascending) =>
                                              _sort(columnIndex, ascending,
                                                  (d) => d.magazineTitle),
                                        ),
                                        DataColumn(
                                          label: const Text('Period'),
                                          onSort: (columnIndex, ascending) =>
                                              _sort(columnIndex, ascending,
                                                  (d) => d.period),
                                        ),
                                        DataColumn(
                                          label: const Text('Amount'),
                                          numeric: true,
                                          onSort: (columnIndex, ascending) =>
                                              _sort(columnIndex, ascending,
                                                  (d) => d.amount),
                                        ),
                                        DataColumn(
                                          label: const Text('Start Date'),
                                          onSort: (columnIndex, ascending) =>
                                              _sort(columnIndex, ascending,
                                                  (d) => d.startDate),
                                        ),
                                        DataColumn(
                                          label: const Text('End Date'),
                                          onSort: (columnIndex, ascending) =>
                                              _sort(columnIndex, ascending,
                                                  (d) => d.endDate),
                                        ),
                                        DataColumn(
                                          label: const Text('Status'),
                                          onSort: (columnIndex, ascending) =>
                                              _sort(columnIndex, ascending,
                                                  (d) => d.status),
                                        ),
                                      ],
                                      rows: _subscriptions.map((subscription) {
                                        final now = DateTime.now();
                                        final isActive =
                                            subscription.endDate.isAfter(now);

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                                Text(subscription.userName)),
                                            DataCell(Text(
                                                subscription.magazineTitle)),
                                            DataCell(Text(subscription.period)),
                                            DataCell(Text(
                                                '₹${subscription.amount.toStringAsFixed(2)}')),
                                            DataCell(Text(_formatDate(
                                                subscription.startDate))),
                                            DataCell(Text(_formatDate(
                                                subscription.endDate))),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: (isActive
                                                          ? Colors.green
                                                          : Colors.red)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  subscription.status,
                                                  style: TextStyle(
                                                    color: isActive
                                                        ? Colors.green
                                                        : Colors.red,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _processData(Map userSubscriptions, Map users) {
    List<SubscriptionData> subscriptions = [];

    // Reset statistics
    int activeCount = 0;
    double monthlyRev = 0.0;
    double totalRev = 0.0;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    for (var userId in userSubscriptions.keys) {
      final userSubs = userSubscriptions[userId] as Map;
      final userData = users[userId] as Map?;
      final userName = userData?['name'] ?? 'Unknown User';

      userSubs.forEach((subId, subData) {
        try {
          final startDate = DateTime.parse(subData['startDate']);
          final endDate = DateTime.parse(subData['endDate']);
          final amount = (subData['amount'] as num?)?.toDouble() ?? 0.0;
          final status = subData['status'] ?? 'unknown';

          // Calculate statistics
          if (endDate.isAfter(now) && status.toLowerCase() == 'active') {
            activeCount++;
            totalRev += amount;

            if (startDate.isAfter(monthStart)) {
              monthlyRev += amount;
            }
          }

          subscriptions.add(SubscriptionData(
            id: subId,
            userId: userId,
            userName: userName,
            magazineTitle: subData['magazineTitle'] ?? 'Unknown Magazine',
            period: subData['period'] ?? 'N/A',
            amount: amount,
            startDate: startDate,
            endDate: endDate,
            status: status,
          ));
        } catch (e) {
          print('Error processing subscription: $e');
        }
      });
    }

    // Update values without setState
    _subscriptions = subscriptions;
    activeSubscriptions = activeCount;
    monthlyRevenue = monthlyRev;
    totalRevenue = totalRev;
  }

  void _sort<T>(int columnIndex, bool ascending,
      T Function(SubscriptionData d) getField) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      _subscriptions.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);

        return ascending
            ? Comparable.compare(aValue as Comparable, bValue as Comparable)
            : Comparable.compare(bValue as Comparable, aValue as Comparable);
      });
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildSummaryCard(String title, String value, Color backgroundColor) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                title.contains('Active')
                    ? Icons.check_circle
                    : title.contains('Monthly')
                        ? Icons.calendar_month
                        : Icons.account_balance_wallet,
                size: 28,
                color: backgroundColor,
              ),
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
                      color: backgroundColor,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... existing helper methods ...
}
