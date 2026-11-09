import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/entities/order_entity.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/repositories/order_repository.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/screens/order_details_screen.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/widgets/order_card.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/widgets/order_status_filter_bar.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';

class MockOrderRepo implements OrderRepository {
  List<OrderEntity> orders = [];

  @override
  Future<List<OrderEntity>> getMyOrders() async => orders;

  @override
  Stream<List<OrderEntity>> watchMyOrders() => Stream.value(orders);

  @override
  Future<OrderEntity?> getOrderById(String orderId) async {
    try {
      return orders.firstWhere((o) => o.orderId == orderId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<OrderEntity> placeOrder({
    required Product product,
    required int quantity,
    String? size,
  }) async {
    throw UnimplementedError();
  }
}

Widget _buildTestableMyOrdersScreen({
  required OrderRepository repository,
  bool embedded = false,
  ValueChanged<int>? onNavigateToTab,
}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        home: MyOrdersScreen(
          orderRepository: repository,
          embedded: embedded,
          onNavigateToTab: onNavigateToTab,
        ),
      );
    },
  );
}

void main() {
  group('MyOrdersScreen Widget Tests', () {
    late MockOrderRepo repo;

    const sampleOrders = [
      OrderEntity(
        id: 'ord_1',
        orderId: 'ord_1',
        orderNumber: 'ORD001245',
        clientId: 'c1',
        clientName: 'Ramesh Patel',
        clientMobile: '9876543210',
        companyName: 'Patel Hardware',
        clientCompanyName: 'Patel Hardware',
        productId: 'p1',
        productName: 'UltraTech Cement (53 Grade)',
        unit: 'Bag',
        price: 420.0,
        size: '50 kg',
        quantity: 10,
        amount: '4200',
        totalAmount: '4200',
        status: 'pending',
        createdAt: '2026-11-08T14:15:00.000Z',
        updatedAt: '2026-11-08T14:15:00.000Z',
      ),
      OrderEntity(
        id: 'ord_2',
        orderId: 'ord_2',
        orderNumber: 'ORD001244',
        clientId: 'c1',
        clientName: 'Ramesh Patel',
        clientMobile: '9876543210',
        companyName: 'Patel Hardware',
        clientCompanyName: 'Patel Hardware',
        productId: 'p2',
        productName: 'ACC Cement (OPC)',
        unit: 'Bag',
        price: 415.0,
        size: '50 kg',
        quantity: 20,
        amount: '8300',
        totalAmount: '8300',
        status: 'confirmed',
        createdAt: '2026-11-07T11:40:00.000Z',
        updatedAt: '2026-11-07T11:40:00.000Z',
      ),
      OrderEntity(
        id: 'ord_3',
        orderId: 'ord_3',
        orderNumber: 'ORD001243',
        clientId: 'c1',
        clientName: 'Ramesh Patel',
        clientMobile: '9876543210',
        companyName: 'Patel Hardware',
        clientCompanyName: 'Patel Hardware',
        productId: 'p3',
        productName: 'Ambuja Cement (53 Grade)',
        unit: 'Bag',
        price: 430.0,
        size: '50 kg',
        quantity: 15,
        amount: '6450',
        totalAmount: '6450',
        status: 'in_process',
        createdAt: '2026-11-06T16:20:00.000Z',
        updatedAt: '2026-11-06T16:20:00.000Z',
      ),
      OrderEntity(
        id: 'ord_4',
        orderId: 'ord_4',
        orderNumber: 'ORD001242',
        clientId: 'c1',
        clientName: 'Ramesh Patel',
        clientMobile: '9876543210',
        companyName: 'Patel Hardware',
        clientCompanyName: 'Patel Hardware',
        productId: 'p4',
        productName: 'Birla White Cement',
        unit: 'Bag',
        price: 450.0,
        size: '50 kg',
        quantity: 12,
        amount: '5400',
        totalAmount: '5400',
        status: 'completed',
        createdAt: '2026-11-04T10:05:00.000Z',
        updatedAt: '2026-11-04T10:05:00.000Z',
      ),
    ];

    setUp(() {
      repo = MockOrderRepo();
    });

    testWidgets('renders green header, filter bar, and all sample order cards', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repo.orders = sampleOrders;

      await tester.pumpWidget(_buildTestableMyOrdersScreen(repository: repo));
      await tester.pumpAndSettle();

      // Top green header
      expect(find.text('My Orders'), findsWidgets);

      // Filters
      expect(find.byType(OrderStatusFilterBar), findsOneWidget);

      // Cards
      expect(find.byType(OrderCard), findsNWidgets(4));
      expect(find.text('Order #ORD001245'), findsOneWidget);
      expect(find.text('Order #ORD001244'), findsOneWidget);
      expect(find.text('Order #ORD001243'), findsOneWidget);
      expect(find.text('Order #ORD001242'), findsOneWidget);
    });

    testWidgets('filters orders when tapping filter tabs', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repo.orders = sampleOrders;

      await tester.pumpWidget(_buildTestableMyOrdersScreen(repository: repo));
      await tester.pumpAndSettle();

      // Tap Pending tab inside filter bar
      final pendingFilter = find.descendant(
        of: find.byType(OrderStatusFilterBar),
        matching: find.text('Pending'),
      );
      await tester.tap(pendingFilter);
      await tester.pumpAndSettle();

      expect(find.byType(OrderCard), findsOneWidget);
      expect(find.text('Order #ORD001245'), findsOneWidget);
      expect(find.text('Order #ORD001244'), findsNothing);

      // Tap Confirmed tab inside filter bar
      final confirmedFilter = find.descendant(
        of: find.byType(OrderStatusFilterBar),
        matching: find.text('Confirmed'),
      );
      await tester.tap(confirmedFilter);
      await tester.pumpAndSettle();

      expect(find.byType(OrderCard), findsOneWidget);
      expect(find.text('Order #ORD001244'), findsOneWidget);

      // Tap All tab inside filter bar to restore all cards
      final allFilter = find.descendant(
        of: find.byType(OrderStatusFilterBar),
        matching: find.text('All'),
      );
      await tester.tap(allFilter);
      await tester.pumpAndSettle();

      expect(find.byType(OrderCard), findsNWidgets(4));
    });

    testWidgets('tapping an order card navigates to OrderDetailsScreen', (
      WidgetTester tester,
    ) async {
      repo.orders = sampleOrders;

      await tester.pumpWidget(_buildTestableMyOrdersScreen(repository: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Order #ORD001245'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailsScreen), findsOneWidget);
      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('Order Summary'), findsOneWidget);
    });

    testWidgets('displays empty state when no orders exist', (
      WidgetTester tester,
    ) async {
      repo.orders = [];

      await tester.pumpWidget(_buildTestableMyOrdersScreen(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('No orders placed yet'), findsOneWidget);
      expect(find.text('Browse Products'), findsOneWidget);
    });
  });
}
