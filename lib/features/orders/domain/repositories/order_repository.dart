import 'package:amarnath_enterprise_client_app/features/orders/domain/entities/order_entity.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';

abstract class OrderRepository {
  /// Places a new order for the currently authenticated Client.
  Future<OrderEntity> placeOrder({
    required Product product,
    required int quantity,
    String? size,
  });

  /// Retrieves orders placed by the current client.
  Future<List<OrderEntity>> getMyOrders();

  /// Realtime stream of orders placed by the current client.
  Stream<List<OrderEntity>> watchMyOrders();

  /// Retrieves a single order by its ID.
  Future<OrderEntity?> getOrderById(String orderId);
}
