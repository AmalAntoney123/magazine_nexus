import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<bool> isUserAdmin(String uid) async {
    final snapshot =
        await _database.child('users').child(uid).child('role').get();
    return snapshot.exists && snapshot.value == 'admin';
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);

      // Initialize user data in Realtime Database
      await _database.child('users').child(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'createdAt': ServerValue.timestamp,
        'address': '', // Initialize empty address
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user is disabled
      final userSnapshot =
          await _database.child('users').child(userCredential.user!.uid).get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        if (userData['disabled'] == true) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'This account has been disabled by an administrator.',
          );
        }
      }

      // Update last login timestamp
      await _database.child('users').child(userCredential.user!.uid).update({
        'lastLogin': ServerValue.timestamp,
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) throw Exception('No user logged in');

      // Reauthenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserAddress() async {
    final user = getCurrentUser();
    if (user == null) return null;

    final snapshot =
        await _database.child('users').child(user.uid).child('address').get();

    if (!snapshot.exists) return null;

    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  Future<void> updateUserAddress(Map<String, String> address) async {
    final user = getCurrentUser();
    if (user == null) throw Exception('No user logged in');

    await _database
        .child('users')
        .child(user.uid)
        .child('address')
        .update(address);
  }
}
