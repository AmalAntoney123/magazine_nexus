import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'appwrite_service.dart';

class AuthService {
  final Account account = AppwriteService.account;

  Future<User> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<Session> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return session;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final user = await account.get();
      return user;
    } catch (e) {
      return null;
    }
  }
}
