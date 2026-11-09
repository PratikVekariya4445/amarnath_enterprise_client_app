import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:amarnath_enterprise_client_app/core/constants/database_paths.dart';
import 'package:amarnath_enterprise_client_app/core/errors/auth_error_mapper.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({
    FirebaseAuth? auth,
    FirebaseDatabase? database,
  })  : _rawAuth = auth,
        _rawDatabase = database;

  final FirebaseAuth? _rawAuth;
  final FirebaseDatabase? _rawDatabase;

  bool get isFirebaseAvailable => _rawAuth != null || Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth {
    final raw = _rawAuth;
    if (raw != null) return raw;
    if (Firebase.apps.isEmpty) {
      throw const AuthException(
        'Firebase is not initialized. Please ensure Firebase configuration is loaded.',
        code: 'no-firebase-app',
      );
    }
    return FirebaseAuth.instance;
  }

  String get _databaseUrl {
    if (Firebase.apps.isNotEmpty) {
      final url = Firebase.app().options.databaseURL;
      if (url != null && url.isNotEmpty) {
        return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      }
    }
    return 'https://whats-deleted-8ca7b.firebaseio.com';
  }

  FirebaseDatabase get _database {
    final raw = _rawDatabase;
    if (raw != null) return raw;
    if (Firebase.apps.isEmpty) {
      throw const AuthException(
        'Firebase is not initialized.',
        code: 'no-firebase-app',
      );
    }
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _databaseUrl,
    );
  }

  User? get currentUser {
    if (!isFirebaseAvailable) return null;
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sends a Firebase password reset email to [email].
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (!isFirebaseAvailable) return;
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Checks whether an account exists in the `users` node for the given [mobile].
  Future<bool> checkUserExistsByMobile(String mobile) async {
    if (!isFirebaseAvailable) return false;
    try {
      final snapshot = await _database.ref(DatabasePaths.users).get().timeout(
        const Duration(seconds: 4),
      );
      if (snapshot.exists && snapshot.value is Map) {
        final users = snapshot.value as Map<dynamic, dynamic>;
        for (final entry in users.entries) {
          if (entry.value is Map) {
            final data = entry.value as Map<dynamic, dynamic>;
            final userMobile = data['mobile']?.toString().trim();
            if (userMobile == mobile) {
              return true;
            }
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// Sends a phone verification code via Firebase Phone Authentication.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(FirebaseAuthException e) verificationFailed,
    required void Function(PhoneAuthCredential credential) verificationCompleted,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Signs in with a Phone Authentication credential to obtain verified phone identity.
  Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!isFirebaseAvailable) return;
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  /// Deletes the currently authenticated user session (used to rollback partial registration failures).
  Future<void> deleteCurrentUser() async {
    if (!isFirebaseAvailable) return;
    try {
      await currentUser?.delete();
    } catch (_) {}
  }

  /// Looks up official Owner mobile number from `amarntath_enterprise/users`.
  Future<String?> getOwnerMobile() async {
    if (!isFirebaseAvailable) return null;
    try {
      final snapshot = await _database.ref(DatabasePaths.users).get().timeout(
            const Duration(seconds: 4),
          );
      if (snapshot.exists && snapshot.value is Map) {
        final users = snapshot.value as Map<dynamic, dynamic>;
        for (final entry in users.entries) {
          if (entry.value is Map) {
            final data = entry.value as Map<dynamic, dynamic>;
            final role = data['role']?.toString().toLowerCase().trim();
            final status = data['status']?.toString().toLowerCase().trim();
            if (role == 'owner' &&
                (status == 'approved' || status == 'active')) {
              final mobile = data['mobile']?.toString().trim();
              if (mobile != null && mobile.isNotEmpty) {
                return mobile;
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// REST fallback write helper (PUT, PATCH).
  Future<void> _writeViaRest(
    String path,
    Map<String, dynamic> data, {
    String method = 'PUT',
  }) async {
    HttpClient? client;
    try {
      String? idToken;
      try {
        idToken = await currentUser?.getIdToken();
      } catch (_) {}

      final baseUrl = _databaseUrl;
      final uri = Uri.parse(
        '$baseUrl/$path.json${idToken != null ? '?auth=$idToken' : ''}',
      );

      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.openUrl(method, uri);
      request.headers.contentType = ContentType.json;
      request.write(json.encode(data));
      await request.close().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('REST write error for $path: $e');
    } finally {
      client?.close();
    }
  }

  /// Writes all three registration records (`users`, `clients`, `signupRequests`)
  /// for a newly registered client account.
  Future<void> writeRegistrationRecords({
    required String uid,
    required Map<String, dynamic> userRecord,
    required Map<String, dynamic> clientRecord,
    required Map<String, dynamic> signupRequestRecord,
  }) async {
    final updates = {
      '${DatabasePaths.users}/$uid': userRecord,
      '${DatabasePaths.clients}/$uid': clientRecord,
      '${DatabasePaths.signupRequests}/$uid': signupRequestRecord,
    };

    try {
      await _database.ref().update(updates).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Fallback to REST write for each node if realtime database socket has delay
      await _writeViaRest(DatabasePaths.user(uid), userRecord, method: 'PUT');
      await _writeViaRest(DatabasePaths.client(uid), clientRecord, method: 'PUT');
      await _writeViaRest(
        DatabasePaths.signupRequest(uid),
        signupRequestRecord,
        method: 'PUT',
      );
    }
  }

  /// REST fallback query for Realtime Database.
  Future<Map<dynamic, dynamic>?> _fetchViaRest(String path) async {
    HttpClient? client;
    try {
      String? idToken;
      try {
        idToken = await currentUser?.getIdToken();
      } catch (_) {}

      final baseUrl = _databaseUrl;
      final uri = Uri.parse(
        '$baseUrl/$path.json${idToken != null ? '?auth=$idToken' : ''}',
      );

      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(uri);
      final response =
          await request.close().timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        if (body.trim().isEmpty || body.trim() == 'null') {
          return null;
        }
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('REST fallback query failed: $e');
    } finally {
      client?.close();
    }
    return null;
  }

  /// Reads user authorization record from `amarntath_enterprise/users/{uid}`.
  Future<Map<dynamic, dynamic>?> readUserRecord(String uid) async {
    try {
      final snapshot =
          await _database.ref(DatabasePaths.user(uid)).get().timeout(
                const Duration(seconds: 4),
              );
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }
      return snapshot.value as Map<dynamic, dynamic>?;
    } catch (e) {
      final restRecord = await _fetchViaRest(DatabasePaths.user(uid));
      if (restRecord != null) {
        return restRecord;
      }
      if (e is TimeoutException) {
        throw const AuthException(
          'Connection timed out. Please check your internet connection.',
          code: 'network-timeout',
        );
      }
      if (e is AuthException) rethrow;
      throw AuthException(
        'Failed to read user record: $e',
        code: 'db-read-failed',
      );
    }
  }

  /// Reads client profile record from `amarntath_enterprise/clients/{uid}`.
  Future<Map<dynamic, dynamic>?> readClientRecord(String uid) async {
    try {
      final snapshot =
          await _database.ref(DatabasePaths.client(uid)).get().timeout(
                const Duration(seconds: 4),
              );
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }
      return snapshot.value as Map<dynamic, dynamic>?;
    } catch (e) {
      final restRecord = await _fetchViaRest(DatabasePaths.client(uid));
      if (restRecord != null) {
        return restRecord;
      }
      return null;
    }
  }

  /// Updates client profile record in both `clients/{uid}` and `users/{uid}`.
  Future<void> updateClientProfile({
    required String uid,
    required String name,
    required String companyName,
    required String address,
  }) async {
    final now = DateTime.now().toIso8601String();
    final updates = {
      '${DatabasePaths.clients}/$uid/name': name,
      '${DatabasePaths.clients}/$uid/clientName': name,
      '${DatabasePaths.clients}/$uid/companyName': companyName,
      '${DatabasePaths.clients}/$uid/shopName': companyName,
      '${DatabasePaths.clients}/$uid/address': address,
      '${DatabasePaths.clients}/$uid/updatedAt': now,
      '${DatabasePaths.users}/$uid/name': name,
      '${DatabasePaths.users}/$uid/companyName': companyName,
      '${DatabasePaths.users}/$uid/address': address,
      '${DatabasePaths.users}/$uid/updatedAt': now,
    };

    try {
      await _database.ref().update(updates).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Realtime Database profile update failed, using REST fallback: $e');
      await _writeViaRest(DatabasePaths.client(uid), {
        'name': name,
        'clientName': name,
        'companyName': companyName,
        'shopName': companyName,
        'address': address,
        'updatedAt': now,
      }, method: 'PATCH');
      await _writeViaRest(DatabasePaths.user(uid), {
        'name': name,
        'companyName': companyName,
        'address': address,
        'updatedAt': now,
      }, method: 'PATCH');
    }
  }

  /// Updates the password of the currently authenticated Firebase user.
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No user is currently signed in.', code: 'no-user');
    }
    await user.updatePassword(newPassword);
  }
}
