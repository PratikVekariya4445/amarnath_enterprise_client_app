import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:amarnath_enterprise_client_app/features/orders/data/models/order_model.dart';
import 'package:amarnath_enterprise_client_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/repositories/order_repository.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';
import 'package:amarnath_enterprise_client_app/features/products/presentation/screens/product_detail_screen.dart';

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
    if (lastSavedOrder != null) return [lastSavedOrder!];
    return [];
  }

  @override
  Stream<List<OrderModel>> watchOrdersForClient(String clientId) {
    if (lastSavedOrder != null) return Stream.value([lastSavedOrder!]);
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
  const testProduct = Product(
    id: 'prod_ultratech_53',
    name: 'UltraTech Cement (53 Grade)',
    code: '1001',
    price: 420.0,
    unit: 'Bag',
    brand: 'UltraTech',
    type: 'OPC (Ordinary Portland Cement)',
    weight: '50 kg',
    grade: '53 Grade',
    sizes: ['50 kg'],
    description: '50 kg Bag',
    isActive: true,
    createdAt: '2026-11-01T10:00:00.000Z',
    updatedAt: '2026-11-01T10:00:00.000Z',
  );

  Widget createWidgetUnderTest({
    Product product = testProduct,
    int initialQuantity = 1,
    int cartCount = 3,
    void Function(Product product, int quantity)? onPlaceOrder,
    VoidCallback? onCartPressed,
    OrderRepository? orderRepository,
  }) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          home: ProductDetailScreen(
            product: product,
            initialQuantity: initialQuantity,
            cartItemCount: cartCount,
            onPlaceOrder: onPlaceOrder,
            onCartPressed: onCartPressed,
            orderRepository: orderRepository,
          ),
        );
      },
    );
  }

  group('ProductDetailScreen UI & Interaction Tests', () {
    testWidgets('renders all visual elements matching reference design',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(initialQuantity: 10));
      await tester.pumpAndSettle();

      // 1. App Bar
      expect(find.text('Product Detail'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      // Top bar should not have a cart button
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.shopping_cart_outlined),
        ),
        findsNothing,
      );

      // 2. Product Information
      expect(find.text('UltraTech Cement (53 Grade)'), findsOneWidget);
      expect(find.text('50 kg Bag'), findsOneWidget);
      expect(find.text('In Stock'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // 3. Product Specifications Card
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('UltraTech'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('OPC (Ordinary Portland Cement)'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('50 kg'), findsAtLeastNWidgets(1));
      expect(find.text('Grade'), findsOneWidget);
      expect(find.text('53 Grade'), findsOneWidget);

      // 4. Order Quantity Section
      expect(find.text('Order Quantity'), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // Initial quantity
      expect(find.text('Bag(s)'), findsOneWidget);
      expect(find.text('Total (Estimated)'), findsOneWidget);
      expect(find.text('₹ 4,200'), findsOneWidget); // 420 * 10 = 4200

      // 5. Place Order Button
      expect(find.text('Place Order'), findsOneWidget);
    });

    testWidgets('stepper increments and updates estimated total dynamically',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(initialQuantity: 1, cartCount: 0));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('₹ 420'), findsAtLeastNWidgets(1));

      // Scroll stepper into view and tap + button
      await tester.ensureVisible(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('₹ 840'), findsOneWidget);

      // Tap + button again
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('₹ 1,260'), findsOneWidget);
    });

    testWidgets(
        'stepper decrements and prevents quantity from dropping below 1',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest(initialQuantity: 2));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('₹ 840'), findsOneWidget);

      // Scroll stepper into view and tap - button -> drops to 1
      await tester.ensureVisible(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('₹ 420'), findsAtLeastNWidgets(1));

      // Tap - button again -> must remain 1
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('₹ 420'), findsAtLeastNWidgets(1));
    });

    testWidgets('triggers onPlaceOrder callback with product and quantity',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      Product? placedProduct;
      int? placedQuantity;

      await tester.pumpWidget(createWidgetUnderTest(
        initialQuantity: 5,
        onPlaceOrder: (prod, qty) {
          placedProduct = prod;
          placedQuantity = qty;
        },
      ));
      await tester.pumpAndSettle();

      final placeOrderButton = find.widgetWithText(ElevatedButton, 'Place Order');
      expect(placeOrderButton, findsOneWidget);

      await tester.tap(placeOrderButton);
      await tester.pumpAndSettle();

      expect(placedProduct?.id, testProduct.id);
      expect(placedQuantity, 5);
    });

    testWidgets('places order via OrderRepository and shows success dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeDataSource = FakeOrderRemoteDataSource();
      final repository = OrderRepositoryImpl(dataSource: fakeDataSource);

      await tester.pumpWidget(createWidgetUnderTest(
        initialQuantity: 3,
        orderRepository: repository,
      ));
      await tester.pumpAndSettle();

      final placeOrderButton = find.widgetWithText(ElevatedButton, 'Place Order');
      await tester.tap(placeOrderButton);
      await tester.pumpAndSettle();

      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('View My Orders'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      expect(fakeDataSource.lastSavedOrder, isNotNull);
      expect(fakeDataSource.lastSavedOrder?.quantity, 3);
      expect(fakeDataSource.lastSavedOrder?.clientName, 'Ramesh Patel');
      expect(fakeDataSource.lastSavedOrder?.companyName, 'Patel Hardware');
      expect(fakeDataSource.lastSavedOrder?.totalAmount, '1260'); // 420 * 3
      expect(fakeDataSource.lastSavedOrder?.status, 'pending');
    });

    testWidgets('verifies top app bar does not contain cart action button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final appBarCart = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.shopping_cart_outlined),
      );
      expect(appBarCart, findsNothing);
    });

    testWidgets('displays only specifications available for selected product',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2220);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      const minimalProduct = Product(
        id: 'prod_steel',
        name: 'Steel Rod',
        code: '1001',
        price: 250.0,
        unit: 'Kg',
        sizes: ['6 mm', '8 mm'],
        createdAt: '2026-11-01T10:00:00.000Z',
        updatedAt: '2026-11-01T10:00:00.000Z',
      );

      await tester.pumpWidget(createWidgetUnderTest(product: minimalProduct));
      await tester.pumpAndSettle();

      // Brand, Type, Grade should not be present
      expect(find.text('Brand'), findsNothing);
      expect(find.text('Type'), findsNothing);
      expect(find.text('Grade'), findsNothing);

      // Sizes and Item No should be present
      expect(find.text('Sizes'), findsOneWidget);
      expect(find.text('6 mm, 8 mm'), findsOneWidget);
      expect(find.text('Item No'), findsOneWidget);
      expect(find.text('1001'), findsOneWidget);
    });

    testWidgets('supports responsive layout without overflow',
        (tester) async {
      // Test small phone
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Test large screen / tablet
      tester.view.physicalSize = const Size(1536, 2048);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
