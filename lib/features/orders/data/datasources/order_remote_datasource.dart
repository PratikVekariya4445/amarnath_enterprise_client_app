import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:amarnath_enterprise_client_app/core/constants/database_paths.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/orders/data/models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<void> saveOrder(OrderModel order);
  Future<ClientModel?> getCurrentClientProfile();
  Future<List<OrderModel>> getOrdersForClient(String clientId);
  Stream<List<OrderModel>> watchOrdersForClient(String clientId);
  Future<OrderModel?> getOrderById(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  OrderRemoteDataSourceImpl({
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

  @override
  Future<void> saveOrder(OrderModel order) async {
    final ref = _database
        .ref()
        .child(DatabasePaths.orders)
        .child(order.orderId);

    await ref.set(order.toJson()).timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        throw Exception('Timed out saving order to Firebase');
      },
    );
  }

  @override
  Future<ClientModel?> getCurrentClientProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Try reading from clients node
      final clientSnap = await _database
          .ref()
          .child(DatabasePaths.client(user.uid))
          .get()
          .timeout(const Duration(seconds: 5));

      if (clientSnap.exists && clientSnap.value is Map) {
        return ClientModel.fromJson(
          clientSnap.value as Map<dynamic, dynamic>,
          user.uid,
        );
      }

      // 2. Fallback to users node
      final userSnap = await _database
          .ref()
          .child(DatabasePaths.user(user.uid))
          .get()
          .timeout(const Duration(seconds: 5));

      if (userSnap.exists && userSnap.value is Map) {
        return ClientModel.fromJson(
          userSnap.value as Map<dynamic, dynamic>,
          user.uid,
        );
      }
    } catch (e) {
      debugPrint('[OrderRemoteDataSource] Error reading client profile: $e');
    }

    // 3. Fallback to FirebaseAuth basic info
    return ClientModel(
      id: user.uid,
      name: user.displayName ?? '',
      mobile: user.phoneNumber ?? '',
      companyName: '',
      email: user.email,
      isActive: true,
      createdAt: '',
      updatedAt: '',
    );
  }

  @override
  Future<List<OrderModel>> getOrdersForClient(String clientId) async {
    try {
      final snap = await _database
          .ref()
          .child(DatabasePaths.orders)
          .orderByChild('clientId')
          .equalTo(clientId)
          .get()
          .timeout(const Duration(seconds: 8));

      if (!snap.exists || snap.value == null) {
        return [];
      }

      final data = snap.value;
      final List<OrderModel> orders = [];
      if (data is Map) {
        data.forEach((k, v) {
          if (v is Map) {
            orders.add(OrderModel.fromJson(v, k.toString()));
          }
        });
      }

      orders.sort((a, b) {
        final dateA = DateTime.tryParse(a.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      return orders;
    } catch (e) {
      debugPrint('[OrderRemoteDataSource] Error fetching client orders: $e');
      return [];
    }
  }

  @override
  Stream<List<OrderModel>> watchOrdersForClient(String clientId) {
    if (clientId.isEmpty) {
      return Stream.value(<OrderModel>[]);
    }

    try {
      return _database
          .ref()
          .child(DatabasePaths.orders)
          .orderByChild('clientId')
          .equalTo(clientId)
          .onValue
          .map((event) {
        final snap = event.snapshot;
        if (!snap.exists || snap.value == null) {
          return <OrderModel>[];
        }

        final data = snap.value;
        final List<OrderModel> orders = [];
        if (data is Map) {
          data.forEach((k, v) {
            if (v is Map) {
              orders.add(OrderModel.fromJson(v, k.toString()));
            }
          });
        }

        orders.sort((a, b) {
          final dateA = DateTime.tryParse(a.createdAt) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = DateTime.tryParse(b.createdAt) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });

        return orders;
      });
    } catch (e) {
      debugPrint('[OrderRemoteDataSource] Error setting up orders stream: $e');
      return Stream.value(<OrderModel>[]);
    }
  }

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final snap = await _database
          .ref()
          .child(DatabasePaths.orders)
          .child(orderId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (snap.exists && snap.value is Map) {
        return OrderModel.fromJson(
          snap.value as Map<dynamic, dynamic>,
          orderId,
        );
      }
    } catch (e) {
      debugPrint('[OrderRemoteDataSource] Error fetching order $orderId: $e');
    }
    return null;
  }
}
