import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/main.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('App launches on splash screen and transitions to LoginScreen when unauthenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // Verify splash screen circular loader is shown initially.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Fast-forward past splash duration and fade transition.
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify that the app transitions to LoginScreen.
    expect(find.byType(LoginScreen), findsOneWidget);
    final richTextFinder = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('Welcome Back'),
    );
    expect(richTextFinder, findsOneWidget);
    expect(find.text('Login to your account to manage\nyour orders and rentals'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
