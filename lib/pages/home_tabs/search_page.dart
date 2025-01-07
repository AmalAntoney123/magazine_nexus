import 'package:flutter/material.dart';
import '../../services/appwrite_service.dart';
import '../../services/local_search_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../pdf_viewer_page.dart';
import '../../widgets/subscription_modal.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  String _error = '';

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await LocalSearchService.searchMagazines(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to search magazines: $e';
        _isLoading = false;
      });
    }
  }

  void _showSubscriptionModal(BuildContext context, String magazineId,
      Map<String, dynamic> magazineData) {
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
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
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _performSearch,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Search'),
              ),
            ],
          ),
        ),
        if (_searchResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Found ${_searchResults.length} results',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(child: Text(_error, style: TextStyle(color: Colors.red)));
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text('No results found'));
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text('Enter a search term and press Search'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultCard(result);
      },
    );
  }

  Widget _buildSearchResultCard(SearchResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Magazine Cover Image
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
                      fileId: result.coverUrl,
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
                    Text(
                      result.magazineTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Issue #${result.issueNumber} - ${DateFormat('MMM d, y').format(result.publishDate)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Page ${result.pageNumber}, Line ${result.lineNumber}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.context,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    StreamBuilder(
                      stream: FirebaseDatabase.instance
                          .ref()
                          .child(
                              'subscriptions/${FirebaseAuth.instance.currentUser?.uid}')
                          .onValue,
                      builder: (context, snapshot) {
                        final hasSubscription =
                            _checkSubscription(snapshot, result.magazineId);
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasSubscription
                                  ? Colors.grey.shade200
                                  : Theme.of(context).colorScheme.primary,
                              foregroundColor: hasSubscription
                                  ? Colors.grey.shade700
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: hasSubscription
                                ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PdfViewerPage(
                                          fileId: result.pdfFileId,
                                          title:
                                              '${result.magazineTitle} - Issue #${result.issueNumber}',
                                        ),
                                      ),
                                    )
                                : () => _showSubscriptionModal(
                                      context,
                                      result.magazineId,
                                      {
                                        'title': result.magazineTitle,
                                        'price': result.magazinePrice,
                                        'coverUrl': result.coverUrl,
                                        'description':
                                            result.magazineDescription,
                                        'frequency': result.frequency,
                                      },
                                    ),
                            child: Text(
                              hasSubscription ? 'View Magazine' : 'Subscribe',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }

  bool _checkSubscription(AsyncSnapshot snapshot, String magazineId) {
    if (!snapshot.hasData || snapshot.data?.snapshot?.value == null) {
      return false;
    }

    final subscriptions = Map<String, dynamic>.from(
      snapshot.data!.snapshot!.value as Map,
    );

    return subscriptions.values.any(
      (sub) =>
          sub['magazineId'] == magazineId &&
          sub['status'] == 'active' &&
          DateTime.parse(sub['endDate']).isAfter(DateTime.now()),
    );
  }

  List<TextSpan> _highlightSearchText(String text, String keyword) {
    final List<TextSpan> spans = [];
    final String lowercaseText = text.toLowerCase();
    final String lowercaseKeyword = keyword.toLowerCase();

    int currentIndex = 0;
    int matchIndex = lowercaseText.indexOf(lowercaseKeyword);

    if (matchIndex == -1) {
      spans.add(TextSpan(text: text));
      return spans;
    }

    // Add text before match
    if (matchIndex > 0) {
      spans.add(TextSpan(text: text.substring(0, matchIndex)));
    }

    // Add highlighted match
    spans.add(TextSpan(
      text: text.substring(matchIndex, matchIndex + keyword.length),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
    ));

    // Add remaining text
    if (matchIndex + keyword.length < text.length) {
      spans.add(TextSpan(
        text: text.substring(matchIndex + keyword.length),
      ));
    }

    return spans;
  }
}
