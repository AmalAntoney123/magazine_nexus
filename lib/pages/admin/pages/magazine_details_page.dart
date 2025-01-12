import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../models/magazine.dart';
import '../../../models/magazine_issue.dart';
import '../dialogs/magazine_issue_form_dialog.dart';
import '../../../services/appwrite_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../dialogs/magazine_form_dialog.dart';
import '../../../services/notification_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

class MagazineDetailsPage extends StatelessWidget {
  final Magazine magazine;

  const MagazineDetailsPage({super.key, required this.magazine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(magazine.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Delivery List',
            onPressed: () => _downloadDeliveryList(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditMagazineDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Combined Cover Photo and Details Card
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Photo
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(
                            AppwriteService.getFilePreviewUrl(
                              bucketId: '67718720002aaa542f4d',
                              fileId: magazine.coverUrl,
                            ).toString(),
                          ),
                        ),
                      ),
                    ),
                    // Details Section
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Magazine Details',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                              context, 'Description', magazine.description),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                              context, 'Price', '₹${magazine.price}'),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                              context, 'Frequency', magazine.frequency),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                              context, 'Category', magazine.category),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            'Next Issue Due',
                            magazine.nextIssueDate.toString().split(' ')[0],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Issues Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Issues',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Issue'),
                            onPressed: () => _showAddIssueDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 400,
                        child: _buildIssuesList(),
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
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesList() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref()
          .child('magazine_issues')
          .orderByChild('magazineId')
          .equalTo(magazine.id)
          .onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text('No issues available'));
        }

        Map<dynamic, dynamic> issuesData =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

        return ListView.builder(
          itemCount: issuesData.length,
          itemBuilder: (context, index) {
            String issueId = issuesData.keys.elementAt(index);
            Map<dynamic, dynamic> issueData = issuesData[issueId];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(
                        AppwriteService.getFilePreviewUrl(
                          bucketId: '67718720002aaa542f4d',
                          fileId: issueData['coverUrl'],
                        ).toString(),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  issueData['title'] ?? 'Issue ${issueData['issueNumber']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Release Date: ${issueData['publishDate'].toString().split('T')[0]}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Status: ${issueData['isPublished'] ? 'Published' : 'Draft'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: issueData['isPublished']
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (issueData['pdfFileId'] != null)
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () => _downloadPdf(issueData['pdfFileId']),
                      ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                        const PopupMenuItem(
                          value: 'updateStatus',
                          child: Text('Update Delivery Status'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showAddIssueDialog(
                            context,
                            existingIssue: MagazineIssue(
                              id: issueId,
                              magazineId: magazine.id,
                              title: issueData['title'] ?? '',
                              description: issueData['description'] ?? '',
                              coverUrl: issueData['coverUrl'] ?? '',
                              pdfFileId: issueData['pdfFileId'] ?? '',
                              issueNumber: issueData['issueNumber'] ?? 0,
                              publishDate:
                                  DateTime.parse(issueData['publishDate']),
                              isPublished: issueData['isPublished'] ?? false,
                            ),
                          );
                        } else if (value == 'delete') {
                          _deleteIssue(issueId);
                        } else if (value == 'updateStatus') {
                          _showDeliveryStatusDialog(context, issueId,
                              issueData['deliveryStatus'] ?? 'pending');
                        }
                      },
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _downloadPdf(String pdfUrl) async {
    final Uri url = Uri.parse(
      AppwriteService.getFilePreviewUrl(
        bucketId: '67718720002aaa542f4d',
        fileId: pdfUrl,
      ).toString(),
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _deleteIssue(String issueId) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('magazine_issues/$issueId')
          .remove();
    } catch (e) {
      debugPrint('Error deleting issue: $e');
    }
  }

  void _showAddIssueDialog(BuildContext context,
      {MagazineIssue? existingIssue}) {
    final DateTime publishDate = DateTime.now();
    final int issueNumber = existingIssue?.issueNumber ??
        1; // You might want to calculate the next issue number

    showDialog(
      context: context,
      builder: (context) => MagazineIssueFormDialog(
        magazineId: magazine.id,
        publishDate: publishDate,
        issueNumber: issueNumber,
        existingIssue: existingIssue,
      ),
    );
  }

  void _showEditMagazineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MagazineFormDialog(
        magazine: magazine,
      ),
    );
  }

  void _showDeliveryStatusDialog(
      BuildContext context, String issueId, String currentStatus) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Delivery Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Pending'),
              leading: Radio<String>(
                value: 'pending',
                groupValue: currentStatus,
                onChanged: (value) =>
                    _updateDeliveryStatus(dialogContext, issueId, value!),
              ),
            ),
            ListTile(
              title: const Text('In Transit'),
              leading: Radio<String>(
                value: 'in_transit',
                groupValue: currentStatus,
                onChanged: (value) =>
                    _updateDeliveryStatus(dialogContext, issueId, value!),
              ),
            ),
            ListTile(
              title: const Text('Delivered'),
              leading: Radio<String>(
                value: 'delivered',
                groupValue: currentStatus,
                onChanged: (value) =>
                    _updateDeliveryStatus(dialogContext, issueId, value!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDeliveryStatus(
      BuildContext context, String issueId, String status) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('magazine_issues/$issueId')
          .update({'deliveryStatus': status});

      // If status is "delivered", send a notification
      if (status == 'delivered') {
        // Get the issue details
        final issueSnapshot = await FirebaseDatabase.instance
            .ref()
            .child('magazine_issues/$issueId')
            .get();

        if (issueSnapshot.exists) {
          final issueData = issueSnapshot.value as Map<dynamic, dynamic>;
          final magazineId = issueData['magazineId'] as String;

          // Get magazine details
          final magazineSnapshot = await FirebaseDatabase.instance
              .ref()
              .child('magazines/$magazineId')
              .get();

          if (magazineSnapshot.exists) {
            final magazineData =
                magazineSnapshot.value as Map<dynamic, dynamic>;
            final magazineTitle = magazineData['title'] as String;
            final issueTitle = issueData['title'] as String;

            // Show notification
            await NotificationService.showDeliveryNotification(
              magazineTitle: magazineTitle,
              issueTitle: issueTitle,
            );
          }
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery status updated to ${status.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating delivery status: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating delivery status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadDeliveryList(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final databaseSnapshot = await FirebaseDatabase.instance.ref().get();

      if (!databaseSnapshot.exists) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No data found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final data = databaseSnapshot.value as Map<dynamic, dynamic>;
      final users = data['users'] as Map<dynamic, dynamic>;
      final subscriptions =
          data['subscriptions'] as Map<dynamic, dynamic>? ?? {};

      final activeSubscribers = <Map<String, dynamic>>[];

      subscriptions.forEach((userId, userSubs) {
        if (userSubs is Map) {
          userSubs.forEach((subId, subscription) {
            if (subscription is Map &&
                subscription['magazineId'] == magazine.id &&
                subscription['status'] == 'active') {
              final user = users[userId];
              if (user != null) {
                activeSubscribers.add({
                  'user': user,
                  'subscription': subscription,
                });
              }
            }
          });
        }
      });

      if (activeSubscribers.isEmpty) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active subscribers found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final pdf = pw.Document();

      // Add single page with table
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                magazine.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Delivery List',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              // Table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1), // Name
                  1: const pw.FlexColumnWidth(2), // Address
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Address',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Table rows
                  for (var subscriber in activeSubscribers)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            subscriber['user']['name']?.toString() ?? 'N/A',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            _formatAddress(subscriber['user']['address']),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${DateTime.now().toString().split('.')[0]}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      );

      // Get temporary directory and save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${magazine.title.replaceAll(' ', '_')}_delivery_list.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        Navigator.pop(context); // Remove loading indicator

        // Open PDF directly
        await OpenFile.open(file.path);
      }
    } catch (e) {
      debugPrint('Error generating delivery list: $e');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating delivery list: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper function to format address
  String _formatAddress(Map<dynamic, dynamic>? address) {
    if (address == null) return 'N/A';

    final List<String> parts = [];
    if (address['line1']?.toString().isNotEmpty == true) {
      parts.add(address['line1'].toString());
    }
    if (address['line2']?.toString().isNotEmpty == true) {
      parts.add(address['line2'].toString());
    }
    if (address['city']?.toString().isNotEmpty == true) {
      parts.add(address['city'].toString());
    }
    if (address['state']?.toString().isNotEmpty == true) {
      parts.add(address['state'].toString());
    }
    if (address['postalCode']?.toString().isNotEmpty == true) {
      parts.add(address['postalCode'].toString());
    }

    return parts.join(', ');
  }
}
