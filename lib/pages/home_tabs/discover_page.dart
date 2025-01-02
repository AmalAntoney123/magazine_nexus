import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/appwrite_service.dart';
import '../../services/wishlist_service.dart';
import '../../widgets/subscription_modal.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  String _searchQuery = '';
  String _sortBy = 'title';
  bool _sortAscending = true;

  bool _isNewRelease(dynamic item) {
    final DateTime createdAt =
        DateTime.parse(item['createdAt'] ?? DateTime.now().toIso8601String());
    final magazineAge = DateTime.now().difference(createdAt);
    if (magazineAge.inDays <= 7) return true;

    final DateTime nextIssueDate = DateTime.parse(
        item['nextIssueDate'] ?? DateTime.now().toIso8601String());
    final issueAge = DateTime.now().difference(nextIssueDate);
    return issueAge.inDays <= 7;
  }

  String _getNewReleaseType(dynamic item) {
    final DateTime createdAt =
        DateTime.parse(item['createdAt'] ?? DateTime.now().toIso8601String());
    final magazineAge = DateTime.now().difference(createdAt);
    if (magazineAge.inDays <= 7) return 'New Magazine';

    final DateTime nextIssueDate = DateTime.parse(
        item['nextIssueDate'] ?? DateTime.now().toIso8601String());
    final issueAge = DateTime.now().difference(nextIssueDate);
    if (issueAge.inDays <= 7) return 'New Issue';

    return '';
  }

  Widget _buildNewReleasesSection(List<MapEntry<String, dynamic>> magazines) {
    final newReleases =
        magazines.where((entry) => _isNewRelease(entry.value)).toList();

    if (newReleases.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.new_releases, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'New Releases',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: newReleases.length,
            itemBuilder: (context, index) {
              final entry = newReleases[index];
              return SizedBox(
                width: 200,
                child: _buildNewReleaseCard(context, entry.key, entry.value),
              );
            },
          ),
        ),
        const Divider(height: 16),
      ],
    );
  }

  Widget _buildNewReleaseCard(BuildContext context, String magazineId,
      Map<dynamic, dynamic> magazineData) {
    final newReleaseType = _getNewReleaseType(magazineData);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Color.fromARGB(255, 246, 255, 249),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image with New Release Badge
          Stack(
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
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
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: newReleaseType == 'New Magazine'
                        ? Colors.orange
                        : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    newReleaseType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  magazineData['title'] ?? 'Untitled',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${magazineData['price']}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => _showSubscriptionModal(
                          context, magazineId, magazineData),
                      child: const Text('Subscribe'),
                    ),
                    IconButton(
                      icon: StreamBuilder(
                        stream: WishlistService.getWishlist(),
                        builder: (context, snapshot) {
                          final wishlisted = snapshot.hasData &&
                              (snapshot.data as Map).containsKey(magazineId);
                          return Icon(
                            wishlisted ? Icons.favorite : Icons.favorite_border,
                            color: wishlisted ? Colors.red : null,
                          );
                        },
                      ),
                      onPressed: () =>
                          WishlistService.toggleWishlist(magazineId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                          onPressed: () => _showSubscriptionModal(
                              context, magazineId, magazineData),
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

  void _showSubscriptionModal(BuildContext context, String magazineId,
      Map<dynamic, dynamic> magazineData) {
    final basePrice = (magazineData['price'] as num).toDouble();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SubscriptionModal(
        magazineData: {'id': magazineId, ...magazineData},
        basePrice: basePrice,
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

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildNewReleasesSection(sortedMagazines),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = filteredMagazines[index];
                        return _buildMagazineCard(
                            context, entry.key, entry.value as Map);
                      },
                      childCount: filteredMagazines.length,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
