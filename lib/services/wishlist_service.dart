import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> toggleWishlist(String magazineId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final wishlistRef = _database.child('wishlists/$userId/$magazineId');
    final snapshot = await wishlistRef.get();

    if (snapshot.exists) {
      await wishlistRef.remove();
    } else {
      await wishlistRef.set(true);
    }
  }

  static Stream<Map<dynamic, dynamic>> getWishlist() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value({});
    }

    return _database
        .child('wishlists/$userId')
        .onValue
        .map((event) => event.snapshot.value as Map? ?? {});
  }
}
