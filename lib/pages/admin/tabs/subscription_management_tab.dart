import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SubscriptionManagementTab extends StatelessWidget {
  const SubscriptionManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref().child('subscriptions').onValue,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data?.snapshot?.value == null) {
          return const Center(child: Text('No subscriptions found'));
        }

        Map<dynamic, dynamic> subscriptions =
            snapshot.data!.snapshot!.value as Map;

        return ListView.builder(
          itemCount: subscriptions.length,
          itemBuilder: (context, index) {
            String subscriptionId = subscriptions.keys.elementAt(index);
            Map<dynamic, dynamic> subscriptionData =
                subscriptions[subscriptionId] as Map;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                title: Text('Subscription #${subscriptionId}'),
                subtitle: Text(
                  'Status: ${subscriptionData['status'] ?? 'Unknown'}',
                  style: TextStyle(
                    color: _getStatusColor(subscriptionData['status']),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'User: ${subscriptionData['userName'] ?? 'Unknown'}'),
                        Text('Plan: ${subscriptionData['plan'] ?? 'Unknown'}'),
                        Text(
                            'Start Date: ${subscriptionData['startDate'] ?? 'Unknown'}'),
                        Text(
                            'End Date: ${subscriptionData['endDate'] ?? 'Unknown'}'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Handle subscription cancellation
                              },
                              child: const Text('Cancel Subscription'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Handle subscription extension
                              },
                              child: const Text('Extend Subscription'),
                            ),
                          ],
                        ),
                      ],
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
