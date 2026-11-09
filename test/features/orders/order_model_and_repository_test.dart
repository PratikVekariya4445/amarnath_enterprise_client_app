import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:amarnath_enterprise_client_app/features/orders/data/models/order_model.dart';
import 'package:amarnath_enterprise_client_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';

class FakeOrderRemoteDataSource implements OrderRemoteDataSource {
  OrderModel? lastSavedOrder;
  ClientModel? fakeProfile = const ClientModel(
    id: 'client_uid_123',
    name: 'Ramesh Patel',
    mobile: '9876543210',
    companyName: 'Patel Hardware',
    createdAt: '2026-11-01T10:00:00.000Z',
    updatedAt: '2026-11-01T10:00:00.000Z',
  );

  @override
  Future<void> saveOrder(OrderModel order) async {
    lastSavedOrder = order;
  }

  @override
  Future<ClientModel?> getCurrentClientProfile() async {
    return fakeProfile;
  }

  @override
  Future<List<OrderModel>> getOrdersForClient(String clientId) async {
    if (lastSavedOrder != null) {
      return [lastSavedOrder!];
    }
    return [];
  }

  @override
  Stream<List<OrderModel>> watchOrdersForClient(String clientId) {
    if (lastSavedOrder != null) {
      return Stream.value([lastSavedOrder!]);
    }
    return Stream.value([]);
  }

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    if (lastSavedOrder != null && lastSavedOrder!.orderId == orderId) {
      return lastSavedOrder;
    }
    return null;
  }
}

void main() {
  group('OrderModel Serialization Tests', () {
    test('toJson contains all required order fields and Owner app aliases', () {
      const order = OrderModel(
        id: 'ord_123456789',
        orderId: 'ord_123456789',
        orderNumber: 'ORD54321',
        clientId: 'client_uid_123',
        clientName: 'Ramesh Patel',
        clientMobile: '9876543210',
        companyName: 'Patel Hardware',
        clientCompanyName: 'Patel Hardware',
        productId: 'prod_cement_53',
        productName: 'UltraTech Cement (53 Grade)',
        productImage: 'https://example.com/cement.png',
        productImageUrl: 'https://example.com/cement.png',
        unit: 'Bag',
        price: 420.0,
        size: '50 kg',
        quantity: 10,
        amount: '4200',
        totalAmount: '4200',
        status: 'pending',
        createdAt: '2026-11-09T10:00:00.000Z',
        updatedAt: '2026-11-09T10:00:00.000Z',
      );

      final json = order.toJson();

      // Required fields per prompt:
      expect(json['orderId'], 'ord_123456789');
      expect(json['clientId'], 'client_uid_123');
      expect(json['clientName'], 'Ramesh Patel');
      expect(json['clientMobile'], '9876543210');
      expect(json['companyName'], 'Patel Hardware');
      expect(json['productId'], 'prod_cement_53');
      expect(json['productName'], 'UltraTech Cement (53 Grade)');
      expect(json['productImage'], 'https://example.com/cement.png');
      expect(json['unit'], 'Bag');
      expect(json['price'], 420.0);
      expect(json['quantity'], 10);
      expect(json['totalAmount'], '4200');
      expect(json['status'], 'pending');
      expect(json['createdAt'], '2026-11-09T10:00:00.000Z');
      expect(json['updatedAt'], '2026-11-09T10:00:00.000Z');

      // Compatibility fields with Owner app OrderModel:
      expect(json['id'], 'ord_123456789');
      expect(json['orderNumber'], 'ORD54321');
      expect(json['clientCompanyName'], 'Patel Hardware');
      expect(json['productImageUrl'], 'https://example.com/cement.png');
      expect(json['amount'], '4200');
      expect(json['size'], '50 kg');
    });

    test('fromJson deserializes correctly from map with varied field keys', () {
      final map = {
        'id': 'ord_888',
        'orderNumber': 'ORD888',
        'clientId': 'client_999',
        'clientName': 'Suresh Shah',
        'clientMobile': '9988776655',
        'companyName': 'Shah Steel',
        'productId': 'prod_steel_1',
        'productName': 'Steel Rod',
        'productImageUrl': 'https://example.com/steel.png',
        'unit': 'Kg',
        'price': 250,
        'quantity': 5,
        'amount': '1250',
        'status': 'pending',
        'createdAt': '2026-11-09T09:00:00.000Z',
      };

      final order = OrderModel.fromJson(map, 'ord_888');

      expect(order.orderId, 'ord_888');
      expect(order.clientId, 'client_999');
      expect(order.clientName, 'Suresh Shah');
      expect(order.clientMobile, '9988776655');
      expect(order.companyName, 'Shah Steel');
      expect(order.productId, 'prod_steel_1');
      expect(order.productName, 'Steel Rod');
      expect(order.productImage, 'https://example.com/steel.png');
      expect(order.unit, 'Kg');
      expect(order.price, 250.0);
      expect(order.quantity, 5);
      expect(order.totalAmount, '1250');
      expect(order.status, 'pending');
    });
  });

  group('OrderRepositoryImpl Unit Tests', () {
    const testProduct = Product(
      id: 'prod_ultratech_53',
      name: 'UltraTech Cement (53 Grade)',
      code: '1001',
      price: 420.0,
      unit: 'Bag',
      brand: 'UltraTech',
      weight: '50 kg',
      sizes: ['50 kg'],
      createdAt: '2026-11-01T10:00:00.000Z',
      updatedAt: '2026-11-01T10:00:00.000Z',
    );

    test('placeOrder validates quantity at least 1', () async {
      final fakeDataSource = FakeOrderRemoteDataSource();
      final repository = OrderRepositoryImpl(dataSource: fakeDataSource);

      expect(
        () => repository.placeOrder(product: testProduct, quantity: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('placeOrder creates order with actual client profile and pending status', () async {
      final fakeDataSource = FakeOrderRemoteDataSource();
      final repository = OrderRepositoryImpl(dataSource: fakeDataSource);

      final order = await repository.placeOrder(
        product: testProduct,
        quantity: 10,
      );

      expect(order.clientId, 'client_uid_123');
      expect(order.clientName, 'Ramesh Patel');
      expect(order.clientMobile, '9876543210');
      expect(order.companyName, 'Patel Hardware');
      expect(order.productId, testProduct.id);
      expect(order.productName, testProduct.name);
      expect(order.quantity, 10);
      expect(order.totalAmount, '4200');
      expect(order.status, 'pending');
      expect(order.orderId.startsWith('ord_'), isTrue);
      expect(order.orderNumber.startsWith('ORD'), isTrue);

      expect(fakeDataSource.lastSavedOrder, isNotNull);
      expect(fakeDataSource.lastSavedOrder?.orderId, order.orderId);
    });
  });
}
