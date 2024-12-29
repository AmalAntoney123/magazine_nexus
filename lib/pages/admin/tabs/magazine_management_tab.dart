import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';


class MagazineManagementTab extends StatelessWidget {
  const MagazineManagementTab({super.key});

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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(magazineData['coverUrl'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(magazineData['title'] ?? 'Untitled'),
                  subtitle:
                      Text(magazineData['description'] ?? 'No description'),
                  trailing: PopupMenuButton(
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
                    onSelected: (value) {
                      // Handle menu item selection
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new magazine logic
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
