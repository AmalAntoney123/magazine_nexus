import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/wishlist_service.dart';
import '../../services/appwrite_service.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  Widget _buildMagazineCard(BuildContext context, String magazineId,
      Map<dynamic, dynamic> magazineData) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 120,
              height: 65,
              child: Image.network(
                AppwriteService.getFilePreviewUrl(
                  bucketId: '67718720002aaa542f4d',
                  fileId: magazineData['coverUrl'],
                ).toString(),
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () =>
                              WishlistService.toggleWishlist(magazineId),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      magazineData['description'] ?? 'No description',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          magazineData['frequency'] ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (magazineData['frequency'] != null) ...[
                          const Text(' • '),
                        ],
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
    return StreamBuilder<Map>(
      stream: WishlistService.getWishlist(),
      builder: (context, wishlistSnapshot) {
        if (wishlistSnapshot.hasError) {
          return Center(child: Text('Error: ${wishlistSnapshot.error}'));
        }

        if (!wishlistSnapshot.hasData || wishlistSnapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Your wishlist is empty'),
                SizedBox(height: 8),
                Text(
                  'Add magazines to your wishlist from the Discover tab',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return StreamBuilder(
          stream: FirebaseDatabase.instance
              .ref()
              .child('magazines')
              .orderByChild('isActive')
              .equalTo(true)
              .onValue,
          builder: (context, magazinesSnapshot) {
            if (magazinesSnapshot.hasError) {
              return Center(child: Text('Error: ${magazinesSnapshot.error}'));
            }

            if (!magazinesSnapshot.hasData ||
                magazinesSnapshot.data?.snapshot.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            Map<dynamic, dynamic> allMagazines =
                magazinesSnapshot.data!.snapshot.value as Map;

            // Filter magazines to show only wishlisted ones
            Map<dynamic, dynamic> wishlistedMagazines = {};
            for (var magazineId in wishlistSnapshot.data!.keys) {
              if (allMagazines.containsKey(magazineId)) {
                wishlistedMagazines[magazineId] = allMagazines[magazineId];
              }
            }

            return ListView.builder(
              itemCount: wishlistedMagazines.length,
              itemBuilder: (context, index) {
                String magazineId = wishlistedMagazines.keys.elementAt(index);
                Map<dynamic, dynamic> magazineData =
                    wishlistedMagazines[magazineId] as Map;
                return _buildMagazineCard(context, magazineId, magazineData);
              },
            );
          },
        );
      },
    );
  }
}
