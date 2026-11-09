import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/core/errors/auth_error_mapper.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/signup_screen.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/signup_pending_screen.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/login_screen.dart';

class MockSignupAuthRepository implements AuthRepository {
  bool registerCalled = false;
  String? lastFullName;
  String? lastShopName;
  String? lastMobile;
  String? lastAddress;
  String? lastPassword;
  Exception? exceptionToThrow;

  @override
  Future<void> registerClient({
    required String name,
    required String shopName,
    required String mobile,
    required String address,
    required String password,
  }) async {
    registerCalled = true;
    lastFullName = name;
    lastShopName = shopName;
    lastMobile = mobile;
    lastAddress = address;
    lastPassword = password;
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
  Future<User> loginWithMobileAndPassword({
    required String mobile,
    required String password,
  }) async => throw UnimplementedError();

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

Widget _createTestableSignupScreen({
  AuthRepository? authRepository,
  VoidCallback? onSignupSuccess,
  VoidCallback? onNavigateToLogin,
}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/signup-pending': (context) => const SignupPendingScreen(),
        },
        home: SignupScreen(
          authRepository: authRepository,
          onSignupSuccess: onSignupSuccess,
          onNavigateToLogin: onNavigateToLogin,
        ),
      );
    },
  );
}

void main() {
  group('SignupScreen UI and Interaction Tests', () {
    testWidgets('renders all visual elements matching reference design', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_createTestableSignupScreen());
      await tester.pumpAndSettle();

      // Background and Logo
      final images = find.byType(Image);
      expect(images, findsNWidgets(2));

      // Header Text
      final richTextFinder = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Create Account'),
      );
      expect(richTextFinder, findsOneWidget);
      expect(
        find.text('Sign up to book, manage and track\nyour rentals easily'),
        findsOneWidget,
      );

      // All 6 Input labels
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Enter your full name'), findsOneWidget);

      expect(find.text('Shop Name'), findsOneWidget);
      expect(find.text('Enter your shop name'), findsOneWidget);

      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Enter your mobile number'), findsOneWidget);

      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Enter your shop address'), findsOneWidget);

      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Create a password'), findsOneWidget);

      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Re-enter your password'), findsOneWidget);

      // Buttons and actions
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('toggles password and confirm password visibility independently', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_createTestableSignupScreen());
      await tester.pumpAndSettle();

      final toggleIcons = find.byIcon(Icons.visibility_off_outlined);
      expect(toggleIcons, findsNWidgets(2));

      final editableTexts = find.byType(EditableText);
      expect(editableTexts, findsNWidgets(6));

      // Initially both password fields are obscured
      expect(tester.widget<EditableText>(editableTexts.at(4)).obscureText, isTrue);
      expect(tester.widget<EditableText>(editableTexts.at(5)).obscureText, isTrue);

      // Toggle first password field
      await tester.ensureVisible(toggleIcons.first);
      await tester.tap(toggleIcons.first);
      await tester.pump();

      expect(tester.widget<EditableText>(editableTexts.at(4)).obscureText, isFalse);
      expect(tester.widget<EditableText>(editableTexts.at(5)).obscureText, isTrue);

      // Toggle confirm password field
      final remainingOffToggle = find.byIcon(Icons.visibility_off_outlined);
      await tester.ensureVisible(remainingOffToggle);
      await tester.tap(remainingOffToggle);
      await tester.pump();

      expect(tester.widget<EditableText>(editableTexts.at(4)).obscureText, isFalse);
      expect(tester.widget<EditableText>(editableTexts.at(5)).obscureText, isFalse);
    });

    testWidgets('validates required fields on empty submit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_createTestableSignupScreen());
      await tester.pumpAndSettle();

      final signUpBtn = find.text('Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pump();

      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter your shop name'), findsOneWidget);
      expect(find.text('Please enter your mobile number'), findsOneWidget);
      expect(find.text('Please enter your shop address'), findsOneWidget);
      expect(find.text('Please create a password'), findsOneWidget);
      expect(find.text('Please re-enter your password'), findsOneWidget);
    });

    testWidgets('validates password mismatch and length', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_createTestableSignupScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your full name'),
        'Rajesh Kumar',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your shop name'),
        'Kumar Textiles',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your mobile number'),
        '9876543210',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your shop address'),
        'Shop 12, Main Bazaar, Surat',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a password'),
        '123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        '456',
      );

      final signUpBtn = find.text('Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('submits valid registration and shows success dialog', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockSignupAuthRepository();
      await tester.pumpWidget(
        _createTestableSignupScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your full name'),
        'Rajesh Kumar',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your shop name'),
        'Kumar Textiles',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your mobile number'),
        '9876543210',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your shop address'),
        'Shop 12, Main Bazaar, Surat',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a password'),
        'secure123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'secure123',
      );

      final signUpBtn = find.text('Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(mockRepo.registerCalled, isTrue);
      expect(mockRepo.lastFullName, 'Rajesh Kumar');
      expect(mockRepo.lastShopName, 'Kumar Textiles');
      expect(mockRepo.lastMobile, '9876543210');
      expect(mockRepo.lastAddress, 'Shop 12, Main Bazaar, Surat');
      expect(mockRepo.lastPassword, 'secure123');

      // Verify success screen
      expect(find.text('Registration Submitted!'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('handles duplicate account error gracefully', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockSignupAuthRepository()
        ..exceptionToThrow = const AuthException(
          'An account is already registered with this mobile number. Please log in.',
        );

      await tester.pumpWidget(
        _createTestableSignupScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your full name'),
        'Rajesh Kumar',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your shop name'),
        'Kumar Textiles',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your mobile number'),
        '9876543210',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your shop address'),
        'Shop 12, Main Bazaar, Surat',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Create a password'),
        'secure123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'secure123',
      );

      final signUpBtn = find.text('Sign Up');
      await tester.ensureVisible(signUpBtn);
      await tester.tap(signUpBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text(
          'An account is already registered with this mobile number. Please log in.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('triggers onNavigateToLogin callback when Login section is clicked', (
      WidgetTester tester,
    ) async {
      bool loginClicked = false;
      await tester.pumpWidget(
        _createTestableSignupScreen(
          onNavigateToLogin: () => loginClicked = true,
        ),
      );
      await tester.pumpAndSettle();

      final loginBtn = find.text('Login');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();

      expect(loginClicked, isTrue);
    });

    testWidgets('verifies responsive layout without overflow across various screen sizes', (
      WidgetTester tester,
    ) async {
      final screenSizes = [
        const Size(320, 568), // Small phone
        const Size(360, 640), // Standard Android
        const Size(360, 800), // Tall Android
        const Size(393, 852), // iPhone 15
        const Size(412, 915), // Pixel 7
        const Size(768, 1024), // Tablet
      ];

      for (final size in screenSizes) {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(_createTestableSignupScreen());
        await tester.pump();

        final err = tester.takeException();
        expect(err, isNull);
        expect(find.byType(SignupScreen), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
