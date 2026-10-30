import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  /// Authenticates a client with mobile number and password.
  /// Validates that role == "client" and status == "approved".
  Future<User> loginWithMobileAndPassword({
    required String mobile,
    required String password,
  });

  /// Checks if a client is currently authenticated and approved.
  Future<User?> getCurrentApprovedClient();

  /// Signs the current user out.
  Future<void> signOut();

  /// Saves remember-me preferences.
  Future<void> saveRememberMe({required bool remember, required String mobile});

  /// Retrieves saved remember-me preferences.
  Future<({bool remember, String mobile})> getRememberMe();
}
