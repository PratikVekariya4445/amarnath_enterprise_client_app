import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/login_screen.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/core/errors/auth_error_mapper.dart';

class MockAuthRepository implements AuthRepository {
  bool loginCalled = false;
  String? lastMobile;
  String? lastPassword;
  Exception? exceptionToThrow;

  @override
  Future<User> loginWithMobileAndPassword({
    required String mobile,
    required String password,
  }) async {
    loginCalled = true;
    lastMobile = mobile;
    lastPassword = password;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    throw UnimplementedError(); // Not needed if onLoginSuccess handles it or test stops
  }

  @override
  Future<void> registerClient({
    required String name,
    required String shopName,
    required String mobile,
    required String address,
    required String password,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
  }

  @override
  Future<void> sendPasswordResetOtp({
    required String mobile,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    void Function(PhoneAuthCredential credential)? onVerificationCompleted,
    int? forceResendingToken,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
  }

  @override
  Future<User?> getCurrentApprovedClient() async => null;

  @override
  Future<SessionValidationResult> validateStartupSession() async {
    return const SessionValidationResult(status: SessionStatus.unauthenticated);
  }

  @override
  Future<ClientModel?> getCurrentClientProfile() async => null;

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

  bool savedRemember = false;
  String savedMobile = '';

  @override
  Future<void> saveRememberMe({
    required bool remember,
    required String mobile,
  }) async {
    savedRemember = remember;
    savedMobile = mobile;
  }

  @override
  Future<({bool remember, String mobile})> getRememberMe() async {
    return (remember: savedRemember, mobile: savedMobile);
  }

  @override
  Future<String> getOwnerContactNumber() async => '+919876543210';
}

Widget _createTestableLoginScreen({
  AuthRepository? authRepository,
  VoidCallback? onLoginSuccess,
  VoidCallback? onForgotPassword,
  VoidCallback? onSignUp,
}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        home: LoginScreen(
          authRepository: authRepository,
          onLoginSuccess: onLoginSuccess,
          onForgotPassword: onForgotPassword,
          onSignUp: onSignUp,
        ),
      );
    },
  );
}

void main() {
  group('LoginScreen UI and Interaction Tests', () {
    testWidgets('renders all visual elements matching reference design', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_createTestableLoginScreen());
      await tester.pumpAndSettle();

      // Background and Logo
      final images = find.byType(Image);
      expect(images, findsNWidgets(2));

      // Header Text
      final richTextFinder = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Welcome Back'),
      );
      expect(richTextFinder, findsOneWidget);
      expect(
        find.text('Login to your account to manage\nyour orders and rentals'),
        findsOneWidget,
      );

      // Input labels
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Enter your mobile number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);

      // Options
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);

      // Buttons and actions
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
      expect(find.text('New to Amarnath Enterprise?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('toggles password visibility when eye icon is clicked', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_createTestableLoginScreen());
      await tester.pumpAndSettle();

      // Find password field by EditableText
      final editableTexts = find.byType(EditableText);
      expect(editableTexts, findsNWidgets(2));

      EditableText passwordField = tester.widget(editableTexts.last);
      expect(passwordField.obscureText, isTrue);

      // Tap visibility toggle icon
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      passwordField = tester.widget(editableTexts.last);
      expect(passwordField.obscureText, isFalse);
    });

    testWidgets('toggles Remember me checkbox', (WidgetTester tester) async {
      await tester.pumpWidget(_createTestableLoginScreen());
      await tester.pumpAndSettle();

      Checkbox checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      await tester.tap(find.text('Remember me'));
      await tester.pump();

      checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('validates empty or invalid mobile number and displays error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_createTestableLoginScreen());
      await tester.pumpAndSettle();

      // Tap Login with empty fields
      final loginBtn = find.text('Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();

      expect(find.text('Please enter your mobile number'), findsOneWidget);

      // Enter invalid mobile number (e.g. 12345)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your mobile number'),
        '12345',
      );
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();

      expect(
        find.text('Enter a valid 10-digit Indian mobile number.'),
        findsOneWidget,
      );
    });

    testWidgets('validates empty password and displays error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_createTestableLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your mobile number'),
        '9876543210',
      );
      final loginBtn = find.text('Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('displays authorization error in snackbar when owner tries to login', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockAuthRepository()
        ..exceptionToThrow = const ClientAccessDeniedException();

      await tester.pumpWidget(
        _createTestableLoginScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your mobile number'),
        '9876543210',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        'secret123',
      );

      final loginBtn = find.text('Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockRepo.loginCalled, isTrue);
      expect(
        find.text(
          'Access denied. Owner accounts cannot log in to the Client app.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays authorization error when client account is pending', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockAuthRepository()
        ..exceptionToThrow = ClientNotApprovedException('pending');

      await tester.pumpWidget(
        _createTestableLoginScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your mobile number'),
        '9876543210',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        'secret123',
      );

      final loginBtn = find.text('Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockRepo.loginCalled, isTrue);
      expect(
        find.text(
          'Your registration is still awaiting Owner approval. You can log in once your account has been approved.',
        ),
        findsOneWidget,
      );
      expect(find.text('Contact Owner'), findsOneWidget);
    });

    testWidgets('displays rejected dialog when client account is rejected', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockAuthRepository()
        ..exceptionToThrow = ClientNotApprovedException('rejected');

      await tester.pumpWidget(
        _createTestableLoginScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your mobile number'),
        '9876543210',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        'secret123',
      );

      final loginBtn = find.text('Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockRepo.loginCalled, isTrue);
      expect(
        find.text(
          'Your registration request has not been approved. Please contact Amarnath Enterprise for assistance.',
        ),
        findsOneWidget,
      );
      expect(find.text('Call Owner'), findsOneWidget);
      expect(find.text('WhatsApp Us'), findsOneWidget);
    });

    testWidgets('triggers onForgotPassword callback', (
      WidgetTester tester,
    ) async {
      bool forgotTapped = false;
      await tester.pumpWidget(
        _createTestableLoginScreen(onForgotPassword: () => forgotTapped = true),
      );
      await tester.pumpAndSettle();

      final forgotBtn = find.text('Forgot Password?');
      await tester.ensureVisible(forgotBtn);
      await tester.tap(forgotBtn);
      await tester.pump();

      expect(forgotTapped, isTrue);
    });

    testWidgets('triggers onSignUp callback', (WidgetTester tester) async {
      bool signUpTapped = false;
      await tester.pumpWidget(
        _createTestableLoginScreen(onSignUp: () => signUpTapped = true),
      );
      await tester.pumpAndSettle();

      final signUpBtn = find.text('Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pump();

      expect(signUpTapped, isTrue);
    });

    testWidgets('verifies responsive layout without overflow across various screen sizes', (
      WidgetTester tester,
    ) async {
      final screenSizes = [
        const Size(320, 568), // Small phone (iPhone SE 1st gen)
        const Size(360, 640), // Standard Android 9:16
        const Size(360, 800), // Standard modern Android
        const Size(393, 852), // iPhone 15
        const Size(412, 915), // Pixel 7
        const Size(768, 1024), // Tablet
      ];

      for (final size in screenSizes) {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(_createTestableLoginScreen());
        await tester.pump();

        final err = tester.takeException();
        expect(err, isNull);
        expect(find.byType(LoginScreen), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
