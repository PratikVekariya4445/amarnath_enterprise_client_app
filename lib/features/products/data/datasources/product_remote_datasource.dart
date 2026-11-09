import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:amarnath_enterprise_client_app/core/constants/database_paths.dart';
import 'package:amarnath_enterprise_client_app/features/products/data/models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  ProductRemoteDataSourceImpl({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _injectedDatabase = database,
        _injectedAuth = auth;

  final FirebaseDatabase? _injectedDatabase;
  final FirebaseAuth? _injectedAuth;

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;

  String get _databaseUrl {
    if (_isFirebaseAvailable) {
      final url = Firebase.app().options.databaseURL;
      if (url != null && url.isNotEmpty) {
        return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      }
    }
    return 'https://whats-deleted-8ca7b.firebaseio.com';
  }

  FirebaseDatabase get _database {
    if (_injectedDatabase != null) return _injectedDatabase;
    if (!_isFirebaseAvailable) {
      return FirebaseDatabase.instance;
    }
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _databaseUrl,
    );
  }

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  /// Direct HTTPS REST fallback for reading Realtime Database products node.
  Future<Map<dynamic, dynamic>?> _fetchViaRest(String path) async {
    HttpClient? client;
    try {
      String? idToken;
      try {
        if (_isFirebaseAvailable) {
          idToken = await _auth.currentUser?.getIdToken();
        }
      } catch (_) {}

      final baseUri = Uri.parse('$_databaseUrl/$path.json');
      final uri = idToken != null && idToken.isNotEmpty
          ? baseUri.replace(queryParameters: {'auth': idToken})
          : baseUri;

      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(uri);
      final response =
          await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        if (body.isEmpty || body.trim() == 'null') return null;
        final decoded = json.decode(body);
        if (decoded is Map) {
          return decoded;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[ProductREST] Fetch fallback error for $path: $e');
      return null;
    } finally {
      client?.close();
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    if (!_isFirebaseAvailable && _injectedDatabase == null) {
      return [];
    }

    try {
      final snapshot =
          await _database.ref(DatabasePaths.products).get().timeout(
                const Duration(seconds: 4),
              );

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        return _parseProducts(data);
      }
    } catch (e) {
      debugPrint('[ProductRemoteDataSource] Firebase SDK read failed: $e, trying REST fallback');
    }

    // Try REST fallback
    final restData = await _fetchViaRest(DatabasePaths.products);
    if (restData != null) {
      return _parseProducts(restData);
    }

    return [];
  }

  List<ProductModel> _parseProducts(dynamic rawData) {
    final List<ProductModel> products = [];
    if (rawData is Map) {
      rawData.forEach((key, value) {
        if (value is Map) {
          try {
            products.add(ProductModel.fromJson(value, key.toString()));
          } catch (e) {
            debugPrint('[ProductRemoteDataSource] Failed to parse product $key: $e');
          }
        }
      });
    } else if (rawData is List) {
      for (int i = 0; i < rawData.length; i++) {
        final item = rawData[i];
        if (item is Map) {
          try {
            products.add(ProductModel.fromJson(item, i.toString()));
          } catch (_) {}
        }
      }
    }
    return products;
  }
}
