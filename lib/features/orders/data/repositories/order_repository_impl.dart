import 'package:amarnath_enterprise_client_app/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:amarnath_enterprise_client_app/features/orders/data/models/order_model.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/entities/order_entity.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/repositories/order_repository.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({OrderRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? OrderRemoteDataSourceImpl();

  final OrderRemoteDataSource _dataSource;

  @override
  Future<OrderEntity> placeOrder({
    required Product product,
    required int quantity,
    String? size,
  }) async {
    if (quantity < 1) {
      throw ArgumentError('Order quantity must be at least 1.');
    }

    final profile = await _dataSource.getCurrentClientProfile();

    final clientId = (profile?.id != null && profile!.id.trim().isNotEmpty)
        ? profile.id.trim()
        : 'guest_client';

    final clientName = (profile?.name != null && profile!.name.trim().isNotEmpty)
        ? profile.name.trim()
        : 'Client';

    final clientMobile =
        (profile?.mobile != null && profile!.mobile.trim().isNotEmpty)
            ? profile.mobile.trim()
            : '';

    final companyName =
        (profile?.companyName != null && profile!.companyName.trim().isNotEmpty)
            ? profile.companyName.trim()
            : '';

    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final orderId = 'ord_$timestamp';
    final orderNumber = 'ORD${(timestamp % 90000) + 10000}';
    final totalAmount = (product.price * quantity).toStringAsFixed(0);

    final resolvedSize = size?.trim().isNotEmpty == true
        ? size!.trim()
        : (product.sizes.isNotEmpty ? product.sizes.first : null);

    final order = OrderModel(
      id: orderId,
      orderId: orderId,
      orderNumber: orderNumber,
      clientId: clientId,
      clientName: clientName,
      clientMobile: clientMobile,
      companyName: companyName,
      clientCompanyName: companyName,
      productId: product.id,
      productName: product.name,
      productImage: product.imageUrl,
      productImageUrl: product.imageUrl,
      unit: product.unit,
      price: product.price,
      size: resolvedSize,
      quantity: quantity,
      amount: totalAmount,
      totalAmount: totalAmount,
      status: 'pending',
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );

    await _dataSource.saveOrder(order);
    return order;
  }

  @override
  Future<List<OrderEntity>> getMyOrders() async {
    final profile = await _dataSource.getCurrentClientProfile();
    if (profile == null || profile.id.isEmpty) {
      return [];
    }
    return _dataSource.getOrdersForClient(profile.id);
  }

  @override
  Stream<List<OrderEntity>> watchMyOrders() async* {
    final profile = await _dataSource.getCurrentClientProfile();
    if (profile == null || profile.id.isEmpty) {
      yield <OrderEntity>[];
      return;
    }
    yield* _dataSource.watchOrdersForClient(profile.id);
  }

  @override
  Future<OrderEntity?> getOrderById(String orderId) async {
    return _dataSource.getOrderById(orderId);
  }
}
