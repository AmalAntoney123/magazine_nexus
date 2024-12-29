import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:appwrite/appwrite.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/magazine.dart';
import '../dialogs/magazine_form_dialog.dart';
import '../../../services/appwrite_service.dart';

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
            )),
          ),
        ),
        title: Text(magazineData['title'] ?? 'Untitled'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(magazineData['description'] ?? 'No description'),
            const SizedBox(height: 4),
            Text(
              'Issue #${magazineData['issueNumber']} • ${magazineData['frequency']} • \$${magazineData['price']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text('View Magazine'),
              onPressed: () {
                final viewUrl = AppwriteService.getFileViewUrl(
                  bucketId: '67718396003a69711df7',
                  fileId: magazineData['pdfFileId'],
                );
                // Launch URL in browser or in-app webview
                launchUrl(viewUrl);
              },
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
                        pdfFileId: magazineData['pdfFileId'] ?? '',
                        price: (magazineData['price'] ?? 0.0).toDouble(),
                        frequency: magazineData['frequency'] ?? 'monthly',
                        publishDate: DateTime.parse(
                            magazineData['publishDate'] ??
                                DateTime.now().toIso8601String()),
                        issueNumber: magazineData['issueNumber'] ?? 1,
                        category: magazineData['category'] ?? 'general',
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
