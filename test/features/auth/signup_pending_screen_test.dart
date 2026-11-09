import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/signup_pending_screen.dart';

Widget _createTestableWidget({
  VoidCallback? onCallOwner,
  VoidCallback? onWhatsApp,
  VoidCallback? onBackToLogin,
  String? ownerContactNumber,
}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        routes: {
          '/login': (context) => const Scaffold(body: Text('Login Page')),
        },
        home: SignupPendingScreen(
          onCallOwner: onCallOwner,
          onWhatsApp: onWhatsApp,
          onBackToLogin: onBackToLogin,
          ownerContactNumber: ownerContactNumber ?? '+919876543210',
        ),
      );
    },
  );
}

void main() {
  group('SignupPendingScreen Widget Tests', () {
    testWidgets('renders background, logo, heading, status badge, and cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_createTestableWidget());
      await tester.pumpAndSettle();

      // Background image check
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  'assets/images/img_splash_bg.png',
        ),
        findsOneWidget,
      );

      // Logo check
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  'assets/images/amarnath_enterprise_client_app_logo.png',
        ),
        findsOneWidget,
      );

      // Heading check
      expect(find.text('Registration Submitted!'), findsOneWidget);

      // Status badge check
      expect(find.text('Approval Pending'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

      // Info message check
      expect(
        find.textContaining(
          'Your registration request has been successfully submitted',
        ),
        findsOneWidget,
      );

      // Contact Owner card check
      expect(find.text('Need Help? Contact Us'), findsOneWidget);
      expect(find.text('Call Owner'), findsOneWidget);
      expect(find.text('WhatsApp Us'), findsOneWidget);

      // Back to Login button check
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('triggers onCallOwner callback when Call Owner is tapped', (
      WidgetTester tester,
    ) async {
      bool callOwnerTapped = false;
      await tester.pumpWidget(
        _createTestableWidget(onCallOwner: () => callOwnerTapped = true),
      );
      await tester.pumpAndSettle();

      final callBtn = find.text('Call Owner');
      await tester.ensureVisible(callBtn);
      await tester.tap(callBtn);
      await tester.pump();

      expect(callOwnerTapped, isTrue);
    });

    testWidgets('triggers onWhatsApp callback when WhatsApp Us is tapped', (
      WidgetTester tester,
    ) async {
      bool whatsappTapped = false;
      await tester.pumpWidget(
        _createTestableWidget(onWhatsApp: () => whatsappTapped = true),
      );
      await tester.pumpAndSettle();

      final whatsappBtn = find.text('WhatsApp Us');
      await tester.ensureVisible(whatsappBtn);
      await tester.tap(whatsappBtn);
      await tester.pump();

      expect(whatsappTapped, isTrue);
    });

    testWidgets('triggers onBackToLogin callback when Back to Login is tapped', (
      WidgetTester tester,
    ) async {
      bool backTapped = false;
      await tester.pumpWidget(
        _createTestableWidget(onBackToLogin: () => backTapped = true),
      );
      await tester.pumpAndSettle();

      final backBtn = find.text('Back to Login');
      await tester.ensureVisible(backBtn);
      await tester.tap(backBtn);
      await tester.pump();

      expect(backTapped, isTrue);
    });

    testWidgets(
      'verifies responsive layout without overflow across screen sizes',
      (WidgetTester tester) async {
        final screenSizes = [
          const Size(320, 568), // Small phone (iPhone SE)
          const Size(360, 640), // Standard Android
          const Size(360, 800), // Modern Android
          const Size(393, 852), // iPhone 15
          const Size(412, 915), // Pixel 7
          const Size(768, 1024), // Tablet
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size * 2.0;
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(_createTestableWidget());
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(SignupPendingScreen), findsOneWidget);
          expect(find.text('Registration Submitted!'), findsOneWidget);
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
