import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/appwrite_service.dart';
import '../../services/wishlist_service.dart';
import '../../widgets/subscription_modal.dart';
import '../../pages/magazine_detail_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  String _searchQuery = '';
  String _sortBy = 'title';
  bool _sortAscending = true;
  bool _isNewReleasesExpanded = true;

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isNewReleasesExpanded = !_isNewReleasesExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.new_releases,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'New Releases',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    _isNewReleasesExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_isNewReleasesExpanded) ...[
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: newReleases.length,
                itemBuilder: (context, index) {
                  final entry = newReleases[index];
                  return _buildNewReleaseCard(context, entry.key, entry.value);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildNewReleaseCard(BuildContext context, String magazineId,
      Map<dynamic, dynamic> magazineData) {
    final newReleaseType = _getNewReleaseType(magazineData);

    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    AppwriteService.getFilePreviewUrl(
                      bucketId: '67718720002aaa542f4d',
                      fileId: magazineData['coverUrl'],
                    ).toString(),
                    fit: BoxFit.cover,
                  ),
                  if (newReleaseType.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: newReleaseType == 'New Magazine'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          newReleaseType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    magazineData['title'] ?? 'Untitled',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${magazineData['price']}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      StreamBuilder(
                        stream: FirebaseDatabase.instance
                            .ref()
                            .child('magazine_issues')
                            .onValue,
                        builder: (context, snapshot) {
                          final issueCount =
                              _getIssueCount(magazineId, snapshot);
                          return Text(
                            '$issueCount issues',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder(
                    stream: FirebaseDatabase.instance
                        .ref()
                        .child(
                            'subscriptions/${FirebaseAuth.instance.currentUser?.uid}')
                        .onValue,
                    builder: (context, snapshot) {
                      final isSubscribed = _isSubscribed(snapshot, magazineId);
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSubscribed
                                ? Colors.grey.shade200
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: isSubscribed
                                ? Colors.grey.shade700
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: isSubscribed
                              ? null
                              : () => _showSubscriptionModal(
                                  context, magazineId, magazineData),
                          child: Text(
                            isSubscribed ? 'Subscribed' : 'Subscribe',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
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
      ),
    );
  }

  Widget _buildSortControls() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.sort, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Sort by: '),
          DropdownButton<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'title', child: Text('Title')),
              DropdownMenuItem(value: 'price', child: Text('Price')),
              DropdownMenuItem(value: 'frequency', child: Text('Frequency')),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MagazineDetailPage(
                magazineId: magazineId,
                magazineData: Map<String, dynamic>.from(magazineData),
              ),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(16)),
                child: SizedBox(
                  width: 120,
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.network(
                      AppwriteService.getFilePreviewUrl(
                        bucketId: '67718720002aaa542f4d',
                        fileId: magazineData['coverUrl'],
                      ).toString(),
                      fit: BoxFit.cover,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              magazineData['title'] ?? 'Untitled',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StreamBuilder(
                            stream: WishlistService.getWishlist(),
                            builder: (context, snapshot) {
                              final wishlisted = snapshot.hasData &&
                                  (snapshot.data as Map)
                                      .containsKey(magazineId);
                              return IconButton(
                                icon: Icon(
                                  wishlisted
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: wishlisted ? Colors.red : Colors.grey,
                                ),
                                onPressed: () =>
                                    WishlistService.toggleWishlist(magazineId),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        magazineData['description'] ?? 'No description',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              magazineData['frequency'] ?? '',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${magazineData['price']}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      StreamBuilder(
                        stream: FirebaseDatabase.instance
                            .ref()
                            .child(
                                'subscriptions/${FirebaseAuth.instance.currentUser?.uid}')
                            .onValue,
                        builder: (context, snapshot) {
                          final isSubscribed =
                              _isSubscribed(snapshot, magazineId);
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSubscribed
                                    ? Colors.grey.shade200
                                    : Theme.of(context).colorScheme.primary,
                                foregroundColor: isSubscribed
                                    ? Colors.grey.shade700
                                    : Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: isSubscribed
                                  ? null
                                  : () => _showSubscriptionModal(
                                      context, magazineId, magazineData),
                              child: Text(
                                isSubscribed ? 'Subscribed' : 'Subscribe',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
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

  int _getIssueCount(String magazineId, AsyncSnapshot snapshot) {
    if (!snapshot.hasData || snapshot.data?.snapshot?.value == null) return 0;

    Map<dynamic, dynamic> issues = snapshot.data!.snapshot!.value as Map;
    return issues.values
        .where((issue) => issue['magazineId'] == magazineId)
        .length;
  }

  bool _isSubscribed(AsyncSnapshot snapshot, String magazineId) {
    if (!snapshot.hasData || snapshot.data?.snapshot?.value == null) {
      return false;
    }

    Map<dynamic, dynamic> subscriptions = snapshot.data!.snapshot!.value as Map;
    return subscriptions.values.any(
        (sub) => sub['magazineId'] == magazineId && sub['status'] == 'active');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
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

                  if (!snapshot.hasData ||
                      snapshot.data?.snapshot?.value == null) {
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
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: _buildNewReleasesSection(sortedMagazines),
                            ),
                            _buildSortControls(),
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 80),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final entry = filteredMagazines[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildMagazineCard(
                                    context, entry.key, entry.value as Map),
                              );
                            },
                            childCount: filteredMagazines.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: _buildSearchAndSort(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndSort() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search magazines...',
          prefixIcon:
              Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }
}
