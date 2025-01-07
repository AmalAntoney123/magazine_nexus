import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:appwrite/appwrite.dart';

import '../../../models/magazine.dart';
import '../dialogs/magazine_form_dialog.dart';
import '../../../services/appwrite_service.dart';
import '../dialogs/magazine_issue_form_dialog.dart';
import '../pages/magazine_details_page.dart';

class MagazineManagementTab extends StatelessWidget {
  const MagazineManagementTab({super.key});

  Widget _buildMagazineCard(BuildContext context, String magazineId,
      Map<dynamic, dynamic> magazineData) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 4,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: 120,
                  child: Image.network(
                    AppwriteService.getFilePreviewUrl(
                      bucketId: '67718720002aaa542f4d',
                      fileId: magazineData['coverUrl'],
                    ).toString(),
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      magazineData['title'] ?? 'Untitled',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      magazineData['description'] ?? 'No description',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${magazineData['frequency']} • ₹${magazineData['price']}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('View Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MagazineDetailsPage(
                                  magazine: Magazine(
                                    id: magazineId,
                                    title: magazineData['title'] ?? '',
                                    description:
                                        magazineData['description'] ?? '',
                                    coverUrl: magazineData['coverUrl'] ?? '',
                                    price: (magazineData['price'] ?? 0.0)
                                        .toDouble(),
                                    frequency:
                                        magazineData['frequency'] ?? 'monthly',
                                    category:
                                        magazineData['category'] ?? 'general',
                                    nextIssueDate: DateTime.parse(
                                      magazineData['nextIssueDate'] ??
                                          DateTime.now().toIso8601String(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        PopupMenuButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey[600],
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await showDialog(
                                context: context,
                                builder: (context) => MagazineFormDialog(
                                  magazine: Magazine(
                                    id: magazineId,
                                    title: magazineData['title'] ?? '',
                                    description:
                                        magazineData['description'] ?? '',
                                    coverUrl: magazineData['coverUrl'] ?? '',
                                    price: (magazineData['price'] ?? 0.0)
                                        .toDouble(),
                                    frequency:
                                        magazineData['frequency'] ?? 'monthly',
                                    category:
                                        magazineData['category'] ?? 'general',
                                    nextIssueDate: DateTime.parse(
                                      magazineData['nextIssueDate'] ??
                                          DateTime.now().toIso8601String(),
                                    ),
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              // Show confirmation dialog
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Text(
                                      'Are you sure you want to delete this magazine?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  // Delete from Firebase
                                  await FirebaseDatabase.instance
                                      .ref()
                                      .child('magazines')
                                      .child(magazineId)
                                      .remove();

                                  // Delete files from Appwrite
                                  final client = Client()
                                    ..setEndpoint(
                                        'https://cloud.appwrite.io/v1')
                                    ..setProject('676fc20b003ccf154826');
                                  final storage = Storage(client);

                                  if (magazineData['coverUrl'] != null) {
                                    await storage.deleteFile(
                                      bucketId: '67718720002aaa542f4d',
                                      fileId: magazineData['coverUrl'],
                                    );
                                  }

                                  if (magazineData['pdfFileId'] != null) {
                                    await storage.deleteFile(
                                      bucketId: '67718396003a69711df7',
                                      fileId: magazineData['pdfFileId'],
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Error deleting magazine: $e')),
                                    );
                                  }
                                }
                              }
                            }
                          },
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
    );
  }

  void _checkUpcomingIssues(BuildContext context, Magazine magazine) {
    final now = DateTime.now();
    if (magazine.nextIssueDate.isBefore(now)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${magazine.title} needs a new issue!'),
            action: SnackBarAction(
              label: 'Add Issue',
              onPressed: () {
                _showAddIssueDialog(context, magazine);
              },
            ),
          ),
        );
      });
    }
  }

  DateTime _calculateNextIssueDate(String frequency, DateTime lastIssueDate) {
    switch (frequency) {
      case 'weekly':
        return lastIssueDate.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(
            lastIssueDate.year, lastIssueDate.month + 1, lastIssueDate.day);
      case 'quarterly':
        return DateTime(
            lastIssueDate.year, lastIssueDate.month + 3, lastIssueDate.day);
      default:
        return lastIssueDate.add(const Duration(days: 7));
    }
  }

  Future<void> _showAddIssueDialog(
      BuildContext context, Magazine magazine) async {
    // Get the latest issue number
    final issuesSnapshot = await FirebaseDatabase.instance
        .ref()
        .child('magazine_issues')
        .orderByChild('magazineId')
        .equalTo(magazine.id)
        .get();

    int nextIssueNumber = 1;
    if (issuesSnapshot.exists) {
      final issues = issuesSnapshot.value as Map;
      nextIssueNumber = issues.values
              .map((issue) => issue['issueNumber'] as int)
              .reduce((max, value) => value > max ? value : max) +
          1;
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => MagazineIssueFormDialog(
          magazineId: magazine.id,
          publishDate: magazine.nextIssueDate,
          issueNumber: nextIssueNumber,
        ),
      );

      // After adding the issue, update the magazine's next issue date
      if (context.mounted) {
        final nextIssueDate = _calculateNextIssueDate(
          magazine.frequency,
          magazine.nextIssueDate,
        );

        await FirebaseDatabase.instance
            .ref()
            .child('magazines')
            .child(magazine.id)
            .update({'nextIssueDate': nextIssueDate.toIso8601String()});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref().child('magazines').onValue,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.snapshot?.value == null) {
            return const Center(child: Text('No magazines found'));
          }

          Map<dynamic, dynamic> magazines =
              snapshot.data!.snapshot!.value as Map;

          return ListView.builder(
            itemCount: magazines.length,
            itemBuilder: (context, index) {
              String magazineId = magazines.keys.elementAt(index);
              Map<dynamic, dynamic> magazineData = magazines[magazineId] as Map;

              return _buildMagazineCard(context, magazineId, magazineData);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const MagazineFormDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
