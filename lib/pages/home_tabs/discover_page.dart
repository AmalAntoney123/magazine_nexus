import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/appwrite_service.dart';
import '../../services/wishlist_service.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  String _searchQuery = '';
  String _sortBy = 'title'; // Default sort
  bool _sortAscending = true;

  Widget _buildSearchAndSort() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search magazines...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 8),
          // Sort Options
          Row(
            children: [
              const Text('Sort by: '),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'title', child: Text('Title')),
                  DropdownMenuItem(value: 'price', child: Text('Price')),
                  DropdownMenuItem(
                      value: 'frequency', child: Text('Frequency')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, dynamic>> _sortMagazines(
      Map<dynamic, dynamic> magazines) {
    var entries = magazines.entries
        .map((entry) => MapEntry(entry.key.toString(), entry.value))
        .toList();

    entries.sort((a, b) {
      var aValue = a.value[_sortBy];
      var bValue = b.value[_sortBy];

      if (_sortBy == 'price') {
        aValue = (aValue as num).toDouble();
        bValue = (bValue as num).toDouble();
      }

      int comparison;
      if (aValue is String) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is num) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = 0;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return entries;
  }

  List<MapEntry<String, dynamic>> _filterMagazines(
      List<MapEntry<String, dynamic>> magazines) {
    if (_searchQuery.isEmpty) return magazines;

    return magazines.where((entry) {
      final magazine = entry.value as Map;
      final title = (magazine['title'] ?? '').toString().toLowerCase();
      final description =
          (magazine['description'] ?? '').toString().toLowerCase();
      final frequency = (magazine['frequency'] ?? '').toString().toLowerCase();

      return title.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          frequency.contains(_searchQuery);
    }).toList();
  }

  Widget _buildMagazineCard(BuildContext context, String magazineId,
      Map<dynamic, dynamic> magazineData) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 120,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(
                    AppwriteService.getFilePreviewUrl(
                      bucketId: '67718720002aaa542f4d',
                      fileId: magazineData['coverUrl'],
                    ).toString(),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      magazineData['title'] ?? 'Untitled',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      magazineData['description'] ?? 'No description',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          magazineData['frequency'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Text(' • '),
                        Text(
                          '₹${magazineData['price']}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: StreamBuilder(
                            stream: WishlistService.getWishlist(),
                            builder: (context, snapshot) {
                              final wishlisted = snapshot.hasData &&
                                  (snapshot.data as Map)
                                      .containsKey(magazineId);
                              return Icon(
                                wishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: wishlisted ? Colors.red : null,
                              );
                            },
                          ),
                          onPressed: () =>
                              WishlistService.toggleWishlist(magazineId),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Subscribe'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Subscription feature coming soon!'),
                              ),
                            );
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndSort(),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseDatabase.instance
                .ref()
                .child('magazines')
                .orderByChild('isActive')
                .equalTo(true)
                .onValue,
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data?.snapshot?.value == null) {
                return const Center(child: Text('No magazines available'));
              }

              Map<dynamic, dynamic> magazines =
                  snapshot.data!.snapshot!.value as Map;

              var sortedMagazines = _sortMagazines(magazines);
              var filteredMagazines = _filterMagazines(sortedMagazines);

              if (filteredMagazines.isEmpty) {
                return const Center(
                    child: Text('No magazines match your search'));
              }

              return ListView.builder(
                itemCount: filteredMagazines.length,
                itemBuilder: (context, index) {
                  final entry = filteredMagazines[index];
                  return _buildMagazineCard(
                      context, entry.key, entry.value as Map);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
