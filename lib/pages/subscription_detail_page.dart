import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/appwrite_service.dart';
import 'pdf_viewer_page.dart';

class SubscriptionDetailPage extends StatelessWidget {
  final Map<String, dynamic> subscription;
  final Map<String, dynamic> magazineData;

  const SubscriptionDetailPage({
    super.key,
    required this.subscription,
    required this.magazineData,
  });

  void _showSubscriptionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Status', subscription['status']),
            _buildDetailRow('Period', subscription['period']),
            _buildDetailRow(
                'Start Date',
                DateTime.parse(subscription['startDate'])
                    .toString()
                    .split(' ')[0]),
            _buildDetailRow(
                'End Date',
                DateTime.parse(subscription['endDate'])
                    .toString()
                    .split(' ')[0]),
            _buildDetailRow('Category', magazineData['category']),
            _buildDetailRow('Frequency', magazineData['frequency']),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subscription['magazineTitle']),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSubscriptionDetails(context),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance
            .ref()
            .child('magazine_issues')
            .orderByChild('magazineId')
            .equalTo(magazineData['id'])
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
              .map((e) => {...Map<String, dynamic>.from(e.value), 'id': e.key})
              .toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        magazineData['title'] ?? 'Unknown Magazine',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (magazineData['description'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          magazineData['description'],
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Magazine Issues',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (issuesList.isEmpty)
                        Center(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'New issues are coming soon.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: issuesList.length,
                          itemBuilder: (context, index) {
                            final issue = issuesList[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 4,
                              shadowColor: Colors.black26,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: issue['pdfFileId'] != null
                                    ? () {
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
                                      }
                                    : null,
                                child: Row(
                                  children: [
                                    if (issue['coverUrl'] != null)
                                      SizedBox(
                                        width: 120,
                                        child: AspectRatio(
                                          aspectRatio: 3 / 4,
                                          child: Image.network(
                                            AppwriteService.getFilePreviewUrl(
                                              bucketId: '67718720002aaa542f4d',
                                              fileId: issue['coverUrl'],
                                            ).toString(),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              issue['title'] ??
                                                  'Issue ${issue['issueNumber']}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Published: ${DateTime.parse(issue['publishDate']).toString().split(' ')[0]}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                            ),
                                            if (issue['description'] !=
                                                null) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                issue['description'],
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  _getDeliveryStatusIcon(
                                                      issue['deliveryStatus'] ??
                                                          'pending'),
                                                  size: 16,
                                                  color: _getDeliveryStatusColor(
                                                      issue['deliveryStatus'] ??
                                                          'pending'),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _getDeliveryStatusText(
                                                      issue['deliveryStatus'] ??
                                                          'pending'),
                                                  style: TextStyle(
                                                    color: _getDeliveryStatusColor(
                                                        issue['deliveryStatus'] ??
                                                            'pending'),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (issue['pdfFileId'] !=
                                                    null) ...[
                                                  const Spacer(),
                                                  TextButton.icon(
                                                    icon:
                                                        const Icon(Icons.book),
                                                    label: const Text('Read'),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              PdfViewerPage(
                                                            fileId: issue[
                                                                'pdfFileId'],
                                                            title: issue[
                                                                    'title'] ??
                                                                'Issue ${issue['issueNumber']}',
                                                          ),
                                                        ),
                                                      );
                                                    },
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
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  IconData _getDeliveryStatusIcon(String status) {
    switch (status) {
      case 'delivered':
        return Icons.check_circle;
      case 'in_transit':
        return Icons.local_shipping;
      default:
        return Icons.pending;
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'in_transit':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _getDeliveryStatusText(String status) {
    switch (status) {
      case 'delivered':
        return 'Delivered';
      case 'in_transit':
        return 'In Transit';
      default:
        return 'Pending';
    }
  }
}
