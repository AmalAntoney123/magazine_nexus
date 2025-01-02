import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/appwrite_service.dart';
import '../../widgets/subscription_modal.dart';
import '../../pages/subscription_detail_page.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  void _showSubscriptionModal(
      BuildContext context, Map<dynamic, dynamic> magazineData) {
    final basePrice = (magazineData['price'] as num).toDouble();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SubscriptionModal(
        magazineData: magazineData,
        basePrice: basePrice,
      ),
    );
  }

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

                // Find the magazine using the title
                final magazine = magazines.entries.firstWhere(
                  (entry) =>
                      entry.value['title'] == subscription['magazineTitle'],
                  orElse: () => MapEntry('', {}),
                );
                final magazineData = {
                  ...Map<String, dynamic>.from(magazine.value as Map),
                  'id': magazine.key,
                };

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionDetailPage(
                            subscription: subscription,
                            magazineData: magazineData,
                          ),
                        ),
                      );
                    },
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
                                AppwriteService.getFilePreviewUrl(
                                  bucketId: '67718720002aaa542f4d',
                                  fileId: magazineData['coverUrl'],
                                ).toString(),
                                width: 100,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                          // Subscription Details
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subscription['magazineTitle'] ??
                                            'Unknown Magazine',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      if (magazineData['description'] !=
                                          null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          magazineData['description'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoChip(
                                        icon: Icons.calendar_today,
                                        label:
                                            'Valid until: ${DateTime.parse(subscription['endDate']).toString().split(' ')[0]}',
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildInfoChip(
                                            icon: subscription['status'] ==
                                                    'active'
                                                ? Icons.check_circle
                                                : Icons.error,
                                            label: subscription['status'] ==
                                                    'active'
                                                ? 'Active'
                                                : 'Expired',
                                            color: subscription['status'] ==
                                                    'active'
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          if (subscription['status'] !=
                                              'active') ...[
                                            const Spacer(),
                                            TextButton(
                                              onPressed: () =>
                                                  _showSubscriptionModal(
                                                      context, magazineData),
                                              child:
                                                  const Text('Subscribe Again'),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
          Icon(icon, size: 14, color: color ?? Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.blue,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
