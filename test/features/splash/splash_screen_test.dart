import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/splash/presentation/splash_screen.dart';

Widget _createTestableWidget({
  Widget? nextScreen,
  Duration duration = const Duration(milliseconds: 1000),
}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        home: SplashScreen(
          nextScreen: nextScreen,
          duration: duration,
        ),
      );
    },
  );
}

void main() {
  group('SplashScreen UI and Behavior Tests', () {
    testWidgets('renders background, center logo, and circular loading indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableWidget(
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
    });

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

    testWidgets('verifies layout without overflow across various screen sizes', (
      WidgetTester tester,
    ) async {
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
          _createTestableWidget(duration: const Duration(seconds: 100)),
        );
        await tester.pump();

        // Verify no exceptions / overflow occurred during layout
        expect(tester.takeException(), isNull);
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('cancels timer gracefully on dispose before timeout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableWidget(
          duration: const Duration(seconds: 10),
        ),
      );

      // Replace widget tree before timer fires
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Replaced')),
        ),
      );

      // Advance time beyond the 10 seconds to ensure no error is thrown
      await tester.pump(const Duration(seconds: 11));
      expect(tester.takeException(), isNull);
    });
  });
}
