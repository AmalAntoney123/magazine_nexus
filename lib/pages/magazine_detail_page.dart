import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/appwrite_service.dart';
import '../widgets/subscription_modal.dart';
import 'pdf_viewer_page.dart';

class MagazineDetailPage extends StatelessWidget {
  final String magazineId;
  final Map<String, dynamic> magazineData;

  const MagazineDetailPage({
    super.key,
    required this.magazineId,
    required this.magazineData,
  });

  bool _isSubscribed(AsyncSnapshot snapshot) {
    if (!snapshot.hasData || snapshot.data?.snapshot?.value == null) {
      return false;
    }

    Map<dynamic, dynamic> subscriptions = snapshot.data!.snapshot!.value as Map;
    return subscriptions.values.any(
        (sub) => sub['magazineId'] == magazineId && sub['status'] == 'active');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(magazineData['title'] ?? 'Magazine Details'),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance
            .ref()
            .child('subscriptions/${FirebaseAuth.instance.currentUser?.uid}')
            .onValue,
        builder: (context, AsyncSnapshot subscriptionSnapshot) {
          final isSubscribed = _isSubscribed(subscriptionSnapshot);

          return StreamBuilder(
            stream: FirebaseDatabase.instance
                .ref()
                .child('magazine_issues')
                .orderByChild('magazineId')
                .equalTo(magazineId)
                .onValue,
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final issues = snapshot.data?.snapshot?.value as Map? ?? {};
              final issuesList = issues.entries
                  .map((e) =>
                      {...Map<String, dynamic>.from(e.value), 'id': e.key})
                  .toList();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Magazine Cover
                    if (magazineData['coverUrl'] != null)
                      SizedBox(
                        width: double.infinity,
                        height: 250,
                        child: Image.network(
                          AppwriteService.getFilePreviewUrl(
                            bucketId: '67718720002aaa542f4d',
                            fileId: magazineData['coverUrl'],
                          ).toString(),
                          fit: BoxFit.cover,
                        ),
                      ),

                    // Magazine Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            magazineData['title'] ?? 'Unknown Magazine',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          if (magazineData['description'] != null)
                            Text(
                              magazineData['description'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  magazineData['frequency'] ?? 'N/A',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '₹${magazineData['price']}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Subscribe/View Button based on subscription status
                          if (!isSubscribed)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () =>
                                    _showSubscriptionModal(context),
                                child: const Text(
                                  'Subscribe to Read',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Issues Section
                          Text(
                            'Available Issues',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildIssuesList(context, issuesList, isSubscribed),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIssuesList(
      BuildContext context, List<dynamic> issues, bool isSubscribed) {
    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upcoming_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Stay Tuned!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'New issues are coming soon.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 80,
                child: Image.network(
                  AppwriteService.getFilePreviewUrl(
                    bucketId: '67718720002aaa542f4d',
                    fileId: issue['coverUrl'],
                  ).toString(),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(
              issue['title'] ?? 'Issue ${issue['issueNumber']}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: Text(
              'Published: ${DateTime.parse(issue['publishDate']).toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            trailing: isSubscribed
                ? TextButton.icon(
                    icon: const Icon(Icons.book),
                    label: const Text('Read'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerPage(
                            fileId: issue['pdfFileId'],
                            title: issue['title'] ??
                                'Issue ${issue['issueNumber']}',
                          ),
                        ),
                      );
                    },
                  )
                : const Icon(Icons.lock_outline),
          ),
        );
      },
    );
  }

  void _showSubscriptionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SubscriptionModal(
        magazineData: {'id': magazineId, ...magazineData},
        basePrice: (magazineData['price'] as num).toDouble(),
      ),
    );
  }
}
