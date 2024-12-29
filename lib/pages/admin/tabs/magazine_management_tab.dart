import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:appwrite/appwrite.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/magazine.dart';
import '../../../models/magazine_issue.dart';
import '../dialogs/magazine_form_dialog.dart';
import '../../../services/appwrite_service.dart';
import '../dialogs/magazine_issue_form_dialog.dart';

class MagazineManagementTab extends StatelessWidget {
  const MagazineManagementTab({super.key});

  Widget _buildMagazineCard(BuildContext context, String magazineId,
      Map<dynamic, dynamic> magazineData) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                AppwriteService.getFilePreviewUrl(
                  bucketId: '67718720002aaa542f4d',
                  fileId: magazineData['coverUrl'],
                ).toString(),
              ),
            ),
          ),
        ),
        title: Text(magazineData['title'] ?? 'Untitled'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(magazineData['description'] ?? 'No description'),
            const SizedBox(height: 4),
            Text(
              '${magazineData['frequency']} • \$${magazineData['price']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text('View Details'),
              onPressed: () => _showMagazineDetails(
                context,
                magazineId,
                Magazine(
                  id: magazineId,
                  title: magazineData['title'] ?? '',
                  description: magazineData['description'] ?? '',
                  coverUrl: magazineData['coverUrl'] ?? '',
                  price: (magazineData['price'] ?? 0.0).toDouble(),
                  frequency: magazineData['frequency'] ?? 'monthly',
                  category: magazineData['category'] ?? 'general',
                  nextIssueDate: DateTime.parse(
                    magazineData['nextIssueDate'] ??
                        DateTime.now().toIso8601String(),
                  ),
                ),
              ),
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
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  await showDialog(
                    context: context,
                    builder: (context) => MagazineFormDialog(
                      magazine: Magazine(
                        id: magazineId,
                        title: magazineData['title'] ?? '',
                        description: magazineData['description'] ?? '',
                        coverUrl: magazineData['coverUrl'] ?? '',
                        price: (magazineData['price'] ?? 0.0).toDouble(),
                        frequency: magazineData['frequency'] ?? 'monthly',
                        category: magazineData['category'] ?? 'general',
                        nextIssueDate: DateTime.parse(
                            magazineData['nextIssueDate'] ??
                                DateTime.now().toIso8601String()),
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
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
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
                        ..setEndpoint('https://cloud.appwrite.io/v1')
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
                              content: Text('Error deleting magazine: $e')),
                        );
                      }
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMagazineDetails(
      BuildContext context, String magazineId, Magazine magazine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(magazine.title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Magazine Info Section
              Text('Magazine Details',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Description: ${magazine.description}'),
              Text('Price: \$${magazine.price}'),
              Text('Frequency: ${magazine.frequency}'),
              Text('Category: ${magazine.category}'),
              Text(
                  'Next Issue Due: ${magazine.nextIssueDate.toString().split(' ')[0]}'),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Issues Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Issues',
                      style: Theme.of(context).textTheme.titleMedium),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Issue'),
                    onPressed: () => _showAddIssueDialog(context, magazine),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Issues List
              Expanded(
                child: StreamBuilder(
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

                    if (!snapshot.hasData ||
                        snapshot.data?.snapshot?.value == null) {
                      return const Center(child: Text('No issues found'));
                    }

                    Map<dynamic, dynamic> issues =
                        snapshot.data!.snapshot!.value as Map;

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: issues.length,
                      itemBuilder: (context, index) {
                        String issueId = issues.keys.elementAt(index);
                        Map<dynamic, dynamic> issueData =
                            issues[issueId] as Map;

                        return Card(
                          child: ListTile(
                            title: Text(
                                'Issue #${issueData['issueNumber']} - ${issueData['title']}'),
                            subtitle: Text(
                                'Published: ${DateTime.parse(issueData['publishDate']).toString().split(' ')[0]}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () {
                                    final viewUrl =
                                        AppwriteService.getFileViewUrl(
                                      bucketId: '67718396003a69711df7',
                                      fileId: issueData['pdfFileId'],
                                    );
                                    launchUrl(viewUrl);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    // Show edit issue dialog
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          MagazineIssueFormDialog(
                                        magazineId: magazineId,
                                        publishDate: DateTime.parse(
                                            issueData['publishDate']),
                                        issueNumber: issueData['issueNumber'],
                                        existingIssue: MagazineIssue(
                                          id: issueId,
                                          magazineId: magazineId,
                                          title: issueData['title'],
                                          description: issueData['description'],
                                          coverUrl: issueData['coverUrl'],
                                          pdfFileId: issueData['pdfFileId'],
                                          issueNumber: issueData['issueNumber'],
                                          publishDate: DateTime.parse(
                                              issueData['publishDate']),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Issue'),
                                        content: const Text(
                                            'Are you sure you want to delete this issue?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        // Delete files from Appwrite
                                        await AppwriteService.deleteFile(
                                          bucketId: '67718720002aaa542f4d',
                                          fileId: issueData['coverUrl'],
                                        );
                                        await AppwriteService.deleteFile(
                                          bucketId: '67718396003a69711df7',
                                          fileId: issueData['pdfFileId'],
                                        );

                                        // Delete from Firebase
                                        await FirebaseDatabase.instance
                                            .ref()
                                            .child('magazine_issues')
                                            .child(issueId)
                                            .remove();
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Error deleting issue: $e')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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
