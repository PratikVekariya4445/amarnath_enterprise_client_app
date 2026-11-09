import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:amarnath_enterprise_client_app/firebase_options.dart';
import 'package:amarnath_enterprise_client_app/core/notifications/notification_service.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/splash/presentation/splash_screen.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/login_screen.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/signup_screen.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/signup_pending_screen.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/home_screen.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';
import 'package:amarnath_enterprise_client_app/features/products/presentation/screens/product_detail_screen.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/screens/order_details_screen.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/entities/order_entity.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/screens/my_details_screen.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/screens/change_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp failed or already initialized: $e');
  }

  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('NotificationService.initialize failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (BuildContext p1, Orientation p2, ScreenType p3) {
        return MaterialApp(
          title: 'Amarnath Enterprise Client',
          navigatorKey: NotificationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF075C3F)),
            useMaterial3: true,
          ),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/signup-pending': (context) => const SignupPendingScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const HomeScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/my-details': (context) => const MyDetailsScreen(),
            '/change-password': (context) => const ChangePasswordScreen(),
            '/my-orders': (context) => const MyOrdersScreen(),
            '/order-details': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is OrderEntity) {
                return OrderDetailsScreen(
                  orderId: args.orderId,
                  initialOrder: args,
                );
              }
              if (args is String) {
                return OrderDetailsScreen(orderId: args);
              }
              return const OrderDetailsScreen(orderId: '');
            },
            '/product-detail': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is Product) {
                return ProductDetailScreen(product: args);
              }
              return const ProductDetailScreen(
                product: Product(
                  id: 'prd_default',
                  name: 'Steel Rod',
                  code: '1001',
                  price: 250.0,
                  unit: 'Kg',
                  sizes: ['6 mm', '8 mm', '10 mm'],
                  createdAt: '',
                  updatedAt: '',
                ),
              );
            },
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
