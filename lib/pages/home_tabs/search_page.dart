import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/appwrite_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search magazines...',
              prefixIcon: Icon(Icons.search,
                  color: Theme.of(context).colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseDatabase.instance
                .ref()
                .child('magazines')
                .orderByChild('isActive')
                .equalTo(true)
                .onValue,
            builder: (context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData || snapshot.data?.snapshot?.value == null) {
                return const Center(child: Text('No magazines available'));
              }

              Map<dynamic, dynamic> magazines =
                  snapshot.data!.snapshot!.value as Map;
              var filteredMagazines = magazines.entries.where((entry) {
                final magazine = entry.value as Map;
                final title =
                    (magazine['title'] ?? '').toString().toLowerCase();
                final description =
                    (magazine['description'] ?? '').toString().toLowerCase();
                return title.contains(_searchQuery) ||
                    description.contains(_searchQuery);
              }).toList();

              if (filteredMagazines.isEmpty) {
                return const Center(
                    child: Text('No magazines match your search'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredMagazines.length,
                itemBuilder: (context, index) {
                  final entry = filteredMagazines[index];
                  return _buildSearchResultCard(
                      context, entry.key, entry.value);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(
      BuildContext context, String id, dynamic magazineData) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            AppwriteService.getFilePreviewUrl(
              bucketId: '67718720002aaa542f4d',
              fileId: magazineData['coverUrl'],
            ).toString(),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(magazineData['title'] ?? 'Untitled'),
        subtitle: Text(
          magazineData['description'] ?? 'No description',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          // Navigate to magazine details page
          // TODO: Implement navigation
        },
      ),
    );
  }
}
