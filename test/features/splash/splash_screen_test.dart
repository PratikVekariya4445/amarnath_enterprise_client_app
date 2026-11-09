import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/login_screen.dart';
import 'package:amarnath_enterprise_client_app/features/home/presentation/home_screen.dart';
import 'package:amarnath_enterprise_client_app/features/splash/presentation/splash_screen.dart';

class MockSplashAuthRepository implements AuthRepository {
  SessionValidationResult sessionResult = const SessionValidationResult(
    status: SessionStatus.unauthenticated,
  );

  @override
  Future<SessionValidationResult> validateStartupSession() async =>
      sessionResult;

  @override
  Future<User?> getCurrentApprovedClient() async => null;

  @override
  Future<ClientModel?> getCurrentClientProfile() async => null;

  @override
  Future<String> getOwnerContactNumber() async => '+919876543210';

  @override
  Future<({String mobile, bool remember})> getRememberMe() async =>
      (mobile: '', remember: false);

  @override
  Future<User> loginWithMobileAndPassword({
    required String mobile,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> registerClient({
    required String name,
    required String shopName,
    required String mobile,
    required String address,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> saveRememberMe({
    required bool remember,
    required String mobile,
  }) async {}

  @override
  Future<void> sendPasswordResetOtp({
    required String mobile,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    void Function(PhoneAuthCredential credential)? onVerificationCompleted,
    int? forceResendingToken,
  }) async =>
      throw UnimplementedError();

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
}

Widget _createTestableWidget({
  Widget? nextScreen,
  Duration duration = const Duration(milliseconds: 1000),
  AuthRepository? authRepository,
}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
        home: SplashScreen(
          nextScreen: nextScreen,
          duration: duration,
          authRepository: authRepository,
        ),
      );
    },
  );
}

void main() {
  group('SplashScreen UI and Behavior Tests', () {
    testWidgets(
      'renders background, center logo, and circular loading indicator',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _createTestableWidget(
            nextScreen: const Scaffold(body: Text('Next Screen')),
            duration: const Duration(seconds: 3),
          ),
        );

        // Verify CircularProgressIndicator is present
        final progressFinder = find.byType(CircularProgressIndicator);
        expect(progressFinder, findsOneWidget);

        final progressIndicator = tester.widget<CircularProgressIndicator>(
          progressFinder,
        );
        expect(
          progressIndicator.valueColor,
          isA<AlwaysStoppedAnimation<Color>>().having(
            (a) => a.value,
            'color',
            const Color(0xFF015734),
          ),
        );

        // Verify images are rendered
        final imageFinders = find.byType(Image);
        expect(imageFinders, findsNWidgets(2));

        // Background image check
        final bgFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/img_splash_bg.png' &&
              widget.fit == BoxFit.cover,
        );
        expect(bgFinder, findsOneWidget);

        // Logo image check
        final logoFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/amarnath_enterprise_client_app_logo.png' &&
              widget.fit == BoxFit.contain,
        );
        expect(logoFinder, findsOneWidget);

        // Settle any pending timers before test ends
        await tester.pumpAndSettle(const Duration(seconds: 3));
      },
    );

    testWidgets('navigates to next screen after duration', (
      WidgetTester tester,
    ) async {
      const nextScreenKey = Key('destination_screen');

      await tester.pumpWidget(
        _createTestableWidget(
          nextScreen: const Scaffold(
            key: nextScreenKey,
            body: Text('Next Screen Content'),
          ),
          duration: const Duration(milliseconds: 500),
        ),
      );

      // Destination screen should not be present initially
      expect(find.byKey(nextScreenKey), findsNothing);

      // Fast forward past duration
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Destination screen should now be visible
      expect(find.byKey(nextScreenKey), findsOneWidget);
      expect(find.text('Next Screen Content'), findsOneWidget);
    });

    testWidgets(
      'navigates to HomeScreen when startup session is approved client',
      (WidgetTester tester) async {
        final mockAuth = MockSplashAuthRepository()
          ..sessionResult = const SessionValidationResult(
            status: SessionStatus.approved,
          );

        await tester.pumpWidget(
          _createTestableWidget(
            duration: const Duration(milliseconds: 300),
            authRepository: mockAuth,
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      'navigates to LoginScreen with pending message when session is pending',
      (WidgetTester tester) async {
        final mockAuth = MockSplashAuthRepository()
          ..sessionResult = const SessionValidationResult(
            status: SessionStatus.pending,
            message:
                'Your registration is still awaiting Owner approval. You can log in once your account has been approved.',
          );

        await tester.pumpWidget(
          _createTestableWidget(
            duration: const Duration(milliseconds: 300),
            authRepository: mockAuth,
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(
          find.text(
            'Your registration is still awaiting Owner approval. You can log in once your account has been approved.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'navigates to LoginScreen when session is unauthenticated',
      (WidgetTester tester) async {
        final mockAuth = MockSplashAuthRepository()
          ..sessionResult = const SessionValidationResult(
            status: SessionStatus.unauthenticated,
          );

        await tester.pumpWidget(
          _createTestableWidget(
            duration: const Duration(milliseconds: 300),
            authRepository: mockAuth,
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets(
      'verifies layout without overflow across various screen sizes',
      (WidgetTester tester) async {
        final screenSizes = [
          const Size(320, 568), // Small phone (iPhone SE 1st gen)
          const Size(360, 640), // Standard Android 9:16
          const Size(360, 800), // Standard modern Android
          const Size(393, 852), // iPhone 15
          const Size(412, 915), // Pixel 7 / Large Android
          const Size(768, 1024), // iPad / Tablet
          const Size(800, 1280), // Android 10-inch Tablet
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size * 2.0;
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            _createTestableWidget(
              nextScreen: const Scaffold(),
              duration: const Duration(seconds: 100),
            ),
          );
          await tester.pump();

          // Verify no exceptions / overflow occurred during layout
          expect(tester.takeException(), isNull);
          expect(find.byType(SplashScreen), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets('cancels timer gracefully on dispose before timeout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableWidget(
          nextScreen: const Scaffold(),
          duration: const Duration(seconds: 10),
        ),
      );

      // Replace widget tree before timer fires
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Replaced'))),
      );

      // Advance time beyond the 10 seconds to ensure no error is thrown
      await tester.pump(const Duration(seconds: 11));
      expect(tester.takeException(), isNull);
    });
  });
}
