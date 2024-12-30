import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/wishlist_service.dart';
import '../../services/appwrite_service.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            magazineData['title'] ?? 'Untitled',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () =>
                              WishlistService.toggleWishlist(magazineId),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      magazineData['description'] ?? 'No description',
                      maxLines: 2,
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
                magazinesSnapshot.data?.snapshot?.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            Map<dynamic, dynamic> allMagazines =
                magazinesSnapshot.data!.snapshot!.value as Map;

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
