import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/repositories/product_repository.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/home_screen.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/quick_action_cards.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/widgets/client_bottom_navigation_bar.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/screens/my_orders_screen.dart';

class MockHomeAuthRepository implements AuthRepository {
  ClientModel? mockProfile;

  @override
  Future<ClientModel?> getCurrentClientProfile() async => mockProfile;

  @override
  Future<User?> getCurrentApprovedClient() async => null;

  @override
  Future<SessionValidationResult> validateStartupSession() async {
    return const SessionValidationResult(status: SessionStatus.unauthenticated);
  }

  @override
  Future<User> loginWithMobileAndPassword({
    required String mobile,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> registerClient({
    required String name,
    required String shopName,
    required String mobile,
    required String address,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetOtp({
    required String mobile,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    void Function(PhoneAuthCredential credential)? onVerificationCompleted,
    int? forceResendingToken,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateClientProfile({
    required String name,
    required String companyName,
    required String address,
  }) async {}

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<PhoneAuthCredential> verifyPasswordResetOtp({
    required String verificationId,
    required String smsCode,
  }) async => throw UnimplementedError();

  @override
  Future<void> resetClientPasswordWithVerifiedPhone({
    required String mobile,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> saveRememberMe({
    required bool remember,
    required String mobile,
  }) async {}

  @override
  Future<({bool remember, String mobile})> getRememberMe() async {
    return (remember: false, mobile: '');
  }

  @override
  Future<String> getOwnerContactNumber() async => '+919876543210';
}

class MockHomeProductRepository implements ProductRepository {
  List<Product> mockRecentlyAdded = [];
  List<Product> mockAllProducts = [];
  bool throwError = false;

  @override
  Future<List<Product>> getRecentlyAddedProducts({int limit = 10}) async {
    if (throwError) throw Exception('Database error');
    return mockRecentlyAdded;
  }

  @override
  Future<List<Product>> getProducts() async {
    if (throwError) throw Exception('Database error');
    return mockAllProducts;
  }

  @override
  Future<List<Product>> searchProducts(String query) async => mockAllProducts;
}

Widget _createTestableHomeScreen({
  ProductRepository? productRepository,
  AuthRepository? authRepository,
  String? initialClientName,
  int initialTabIndex = 0,
}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        routes: {
          '/login': (context) => const Scaffold(body: Text('Login Screen')),
          '/home': (context) => const HomeScreen(),
        },
        home: HomeScreen(
          productRepository: productRepository,
          authRepository: authRepository,
          initialClientName: initialClientName,
          initialTabIndex: initialTabIndex,
        ),
      );
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHomeAuthRepository mockAuthRepo;
  late MockHomeProductRepository mockProductRepo;

  final sampleProducts = [
    const Product(
      id: 'prod_1',
      name: 'Steel Rod',
      code: '1001',
      price: 250.0,
      unit: 'Kg',
      sizes: ['6 mm', '8 mm', '10 mm'],
      createdAt: '2026-11-01T10:00:00.000Z',
      updatedAt: '2026-11-01T10:00:00.000Z',
    ),
    const Product(
      id: 'prod_2',
      name: 'Square Pipe',
      code: '1002',
      price: 450.0,
      unit: 'Pcs',
      sizes: ['20 x 20', '25 x 25', '40 x 40'],
      createdAt: '2026-11-02T10:00:00.000Z',
      updatedAt: '2026-11-02T10:00:00.000Z',
    ),
  ];

  setUp(() {
    mockAuthRepo = MockHomeAuthRepository();
    mockProductRepo = MockHomeProductRepository();
    mockProductRepo.mockRecentlyAdded = sampleProducts;
    mockProductRepo.mockAllProducts = sampleProducts;
  });

  group('HomeScreen UI and Component Verification', () {
    testWidgets('renders all visual elements matching reference design', (
      WidgetTester tester,
    ) async {
      mockAuthRepo.mockProfile = const ClientModel(
        id: 'client_123',
        name: 'Monika',
        mobile: '+919876543210',
        companyName: 'Monika Hardware',
        createdAt: '2026-11-01T10:00:00Z',
        updatedAt: '2026-11-01T10:00:00Z',
      );

      await tester.pumpWidget(
        _createTestableHomeScreen(
          authRepository: mockAuthRepo,
          productRepository: mockProductRepo,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header elements
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      final logoFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/amarnath_enterprise_client_app_logo.png',
      );
      expect(logoFinder, findsOneWidget);

      // 2. Personalized greeting
      final greetingFinder = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Hello, Monika! 👋'),
      );
      expect(greetingFinder, findsOneWidget);
      expect(
        find.text('Find products, check availability and place your order.'),
        findsOneWidget,
      );

      // 3. Search Bar
      expect(
        find.text('Search by product name or item number...'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.search), findsOneWidget);

      // 4. Quick Action Cards
      expect(find.text('Browse Products'), findsOneWidget);
      expect(find.text('Explore our product\ncollection'), findsOneWidget);
      expect(find.text('My Orders'), findsNWidgets(2)); // in quick action and bottom nav
      expect(find.text('View and track\nyour orders'), findsOneWidget);

      // 5. Product Range Banner
      final bannerTitleFinder = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Explore Our\nProduct Range'),
      );
      expect(bannerTitleFinder, findsOneWidget);
      expect(
        find.text('Wide variety of products\navailable for your business'),
        findsOneWidget,
      );

      // 6. Recently Added Section
      expect(find.text('Recently Added'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      expect(find.text('Steel Rod'), findsOneWidget);
      expect(find.text('Item No: 1001'), findsOneWidget);
      expect(find.text('Sizes: 6 mm, 8 mm, 10 mm'), findsOneWidget);
      expect(find.text('Square Pipe'), findsOneWidget);
      expect(find.text('Item No: 1002'), findsOneWidget);
      expect(find.text('Sizes: 20 x 20, 25 x 25, 40 x 40'), findsOneWidget);
      expect(find.text('New'), findsNWidgets(2));

      // 7. Persistent Bottom Navigation Bar
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ClientBottomNavigationBar),
          matching: find.text('My Orders'),
        ),
        findsOneWidget,
      );
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows empty state when no products exist in catalog', (
      WidgetTester tester,
    ) async {
      mockProductRepo.mockRecentlyAdded = [];

      await tester.pumpWidget(
        _createTestableHomeScreen(
          authRepository: mockAuthRepo,
          productRepository: mockProductRepo,
          initialClientName: 'Monika',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No products available yet'), findsOneWidget);
      expect(
        find.text('New catalog items will appear here once added.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error state when products fail to load', (
      WidgetTester tester,
    ) async {
      mockProductRepo.throwError = true;

      await tester.pumpWidget(
        _createTestableHomeScreen(
          authRepository: mockAuthRepo,
          productRepository: mockProductRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load products'), findsOneWidget);
    });

    testWidgets('tapping search bar navigates to Browse tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableHomeScreen(
          authRepository: mockAuthRepo,
          productRepository: mockProductRepo,
          initialClientName: 'Monika',
        ),
      );
      await tester.pumpAndSettle();

      final searchBar = find.text('Search by product name or item number...');
      await tester.tap(searchBar);
      await tester.pumpAndSettle();

      // Should be in Browse Catalog tab
      expect(find.text('Browse Catalog'), findsOneWidget);
    });

    testWidgets('tapping Browse Products quick action navigates to Browse tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableHomeScreen(
          authRepository: mockAuthRepo,
          productRepository: mockProductRepo,
          initialClientName: 'Monika',
        ),
      );
      await tester.pumpAndSettle();

      final browseCard = find.text('Browse Products');
      await tester.tap(browseCard);
      await tester.pumpAndSettle();

      expect(find.text('Browse Catalog'), findsOneWidget);
    });

    testWidgets('tapping My Orders quick action navigates to My Orders tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableHomeScreen(
          authRepository: mockAuthRepo,
          productRepository: mockProductRepo,
          initialClientName: 'Monika',
        ),
      );
      await tester.pumpAndSettle();

      final ordersCard = find.descendant(
        of: find.byType(QuickActionCards),
        matching: find.text('My Orders'),
      );
      await tester.tap(ordersCard);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(MyOrdersScreen),
          matching: find.text('My Orders'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping Product Range Banner navigates to Browse tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableHomeScreen(
          authRepository: mockAuthRepo,
          productRepository: mockProductRepo,
          initialClientName: 'Monika',
        ),
      );
      await tester.pumpAndSettle();

      final bannerText =
          find.text('Wide variety of products\navailable for your business');
      await tester.ensureVisible(bannerText);
      await tester.tap(bannerText);
      await tester.pumpAndSettle();

      expect(find.text('Browse Catalog'), findsOneWidget);
    });

    testWidgets('tapping View All in Recently Added navigates to Browse tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableHomeScreen(
          authRepository: mockAuthRepo,
          productRepository: mockProductRepo,
          initialClientName: 'Monika',
        ),
      );
      await tester.pumpAndSettle();

      final viewAllBtn = find.text('View All');
      await tester.ensureVisible(viewAllBtn);
      await tester.tap(viewAllBtn);
      await tester.pumpAndSettle();

      expect(find.text('Browse Catalog'), findsOneWidget);
    });

    testWidgets('bottom navigation switches tabs correctly', (
      WidgetTester tester,
    ) async {
      mockAuthRepo.mockProfile = const ClientModel(
        id: 'client_123',
        name: 'Monika',
        mobile: '+919876543210',
        companyName: 'Monika Hardware',
        createdAt: '2026-11-01T10:00:00Z',
        updatedAt: '2026-11-01T10:00:00Z',
      );

      await tester.pumpWidget(
        _createTestableHomeScreen(
          authRepository: mockAuthRepo,
          productRepository: mockProductRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Products tab
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      expect(find.text('Browse Catalog'), findsOneWidget);

      // Tap My Orders tab
      await tester.tap(find.descendant(
        of: find.byType(ClientBottomNavigationBar),
        matching: find.text('My Orders'),
      ));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(MyOrdersScreen),
          matching: find.text('My Orders'),
        ),
        findsOneWidget,
      );

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Monika Hardware'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Tap Home tab to return
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(
        find.text('Find products, check availability and place your order.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'verifies responsive layout without overflow across multiple device screen sizes',
      (WidgetTester tester) async {
        final screenSizes = [
          const Size(320, 568), // Small phone (iPhone SE)
          const Size(360, 640), // Standard Android 9:16
          const Size(360, 800), // Standard modern Android
          const Size(393, 852), // iPhone 15
          const Size(412, 915), // Pixel 7
          const Size(768, 1024), // Tablet
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size * 2.0;
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            _createTestableHomeScreen(
              authRepository: mockAuthRepo,
              productRepository: mockProductRepo,
              initialClientName: 'Monika',
            ),
          );
          await tester.pump();

          final err = tester.takeException();
          expect(err, isNull);
          expect(find.byType(HomeScreen), findsOneWidget);
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
