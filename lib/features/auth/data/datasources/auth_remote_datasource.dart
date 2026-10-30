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

  Future<void> signOut() async {
    if (!isFirebaseAvailable) return;
    try {
      await _auth.signOut();
    } catch (_) {}
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
}
