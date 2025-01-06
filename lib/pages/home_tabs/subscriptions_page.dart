import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/appwrite_service.dart';
import '../../widgets/subscription_modal.dart';
import '../../pages/subscription_detail_page.dart';

class SubscriptionsPage extends StatelessWidget {
  const SubscriptionsPage({super.key});

  void _showSubscriptionModal(BuildContext context,
      Map<dynamic, dynamic> magazineData, String subscriptionKey) {
    final basePrice = (magazineData['price'] as num).toDouble();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SubscriptionModal(
        magazineData: magazineData,
        basePrice: basePrice,
        existingSubscriptionKey: subscriptionKey,
      ),
    );
  }

  bool isSubscriptionActive(Map<String, dynamic> subscription) {
    try {
      final endDate = DateTime.parse(subscription['endDate']);
      final now = DateTime.now();

      // Check if subscription is still active
      if (now.isAfter(endDate)) return false;

      return true;
    } catch (e) {
      print('Error parsing date: $e');
      return false;
    }
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
                  elevation: 4,
                  shadowColor: Colors.black26,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: isSubscriptionActive(subscription)
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubscriptionDetailPage(
                                  subscription: subscription,
                                  magazineData: magazineData,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (magazineData['coverUrl'] != null)
                          SizedBox(
                            width: 120,
                            height: 160,
                            child: ColorFiltered(
                              colorFilter: isSubscriptionActive(subscription)
                                  ? const ColorFilter.mode(
                                      Colors.transparent,
                                      BlendMode.saturation,
                                    )
                                  : const ColorFilter.matrix([
                                      0.2126,
                                      0.7152,
                                      0.0722,
                                      0,
                                      0,
                                      0.2126,
                                      0.7152,
                                      0.0722,
                                      0,
                                      0,
                                      0.2126,
                                      0.7152,
                                      0.0722,
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      1,
                                      0,
                                    ]),
                              child: Image.network(
                                AppwriteService.getFilePreviewUrl(
                                  bucketId: '67718720002aaa542f4d',
                                  fileId: magazineData['coverUrl'],
                                ).toString(),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subscription['magazineTitle'] ??
                                      'Unknown Magazine',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isSubscriptionActive(subscription)
                                                ? null
                                                : Colors.grey,
                                      ),
                                ),
                                if (magazineData['description'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    magazineData['description'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color:
                                              isSubscriptionActive(subscription)
                                                  ? Colors.grey.shade600
                                                  : Colors.grey,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _buildInfoChip(
                                  icon: Icons.calendar_today,
                                  label:
                                      'Valid until: ${DateTime.parse(subscription['endDate']).toString().split(' ')[0].split('-').reversed.join('-')}',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      icon: isSubscriptionActive(subscription)
                                          ? Icons.check_circle
                                          : Icons.error,
                                      label: isSubscriptionActive(subscription)
                                          ? 'Active'
                                          : 'Expired',
                                      color: isSubscriptionActive(subscription)
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    if (!isSubscriptionActive(
                                        subscription)) ...[
                                      const Spacer(),
                                      ElevatedButton(
                                        onPressed: () => _showSubscriptionModal(
                                          context,
                                          magazineData,
                                          subscriptions.keys.elementAt(index),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Subscribe Again',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
