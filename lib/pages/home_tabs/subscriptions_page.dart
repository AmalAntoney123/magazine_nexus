import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view subscriptions'));
    }

    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref()
          .child('subscriptions')
          .child(user.uid)
          .onValue,
      builder: (context, AsyncSnapshot subscriptionSnapshot) {
        if (subscriptionSnapshot.hasError) {
          return Center(child: Text('Error: ${subscriptionSnapshot.error}'));
        }

        if (subscriptionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!subscriptionSnapshot.hasData ||
            subscriptionSnapshot.data?.snapshot?.value == null) {
          return const Center(
            child: Text('No active subscriptions'),
          );
        }

        final subscriptions = Map<String, dynamic>.from(
            subscriptionSnapshot.data!.snapshot!.value as Map);

        return StreamBuilder(
          stream: FirebaseDatabase.instance.ref().child('magazines').onValue,
          builder: (context, AsyncSnapshot magazineSnapshot) {
            if (magazineSnapshot.hasError) {
              return Center(child: Text('Error: ${magazineSnapshot.error}'));
            }

            if (magazineSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final magazines =
                magazineSnapshot.data?.snapshot?.value as Map? ?? {};

            return ListView.builder(
              itemCount: subscriptions.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final subscription = Map<String, dynamic>.from(
                    subscriptions.values.elementAt(index));
                final magazineData =
                    magazines[subscription['magazineId']] ?? {};

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Magazine Cover
                        if (magazineData['coverUrl'] != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12),
                            ),
                            child: Image.network(
                              magazineData['coverUrl'],
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        // Subscription Details
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subscription['magazineTitle'] ??
                                      'Unknown Magazine',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      icon: Icons.calendar_today,
                                      label:
                                          'Valid until: ${DateTime.parse(subscription['endDate']).toString().split(' ')[0]}',
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      icon: subscription['status'] == 'active'
                                          ? Icons.check_circle
                                          : Icons.error,
                                      label:
                                          'Status: ${subscription['status']}',
                                      color: subscription['status'] == 'active'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Amount paid: ₹${subscription['amount']}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                if (subscription['paymentId'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Payment ID: ${subscription['paymentId']}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color ?? Colors.blue),
          ),
        ],
      ),
    );
  }
}
