import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:amarnath_enterprise_client_app/features/auth/presentation/login_screen.dart';

class MockForgotPasswordAuthRepository implements AuthRepository {
  bool sendOtpCalled = false;
  String? lastMobile;
  Exception? exceptionToThrow;
  String? verificationFailedMessage;
  String verificationIdToEmit = 'test_verification_id_123';
  int? resendTokenToEmit = 12345;

  @override
  Future<void> sendPasswordResetOtp({
    required String mobile,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    void Function(PhoneAuthCredential credential)? onVerificationCompleted,
    int? forceResendingToken,
  }) async {
    sendOtpCalled = true;
    lastMobile = mobile;

    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }

    if (verificationFailedMessage != null) {
      onVerificationFailed(verificationFailedMessage!);
      return;
    }

    onCodeSent(verificationIdToEmit, resendTokenToEmit);
  }

  @override
  Future<void> registerClient({
    required String name,
    required String shopName,
    required String mobile,
    required String address,
    required String password,
  }) async => throw UnimplementedError();

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

Widget _createTestableForgotPasswordScreen({
  AuthRepository? authRepository,
  ValueChanged<String>? onSendOtp,
  VoidCallback? onBack,
  void Function(String verificationId, String mobile)? onOtpSent,
}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        routes: {
          '/login': (context) => const LoginScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
        },
        home: ForgotPasswordScreen(
          authRepository: authRepository,
          onSendOtp: onSendOtp,
          onBack: onBack,
          onOtpSent: onOtpSent,
        ),
      );
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockForgotPasswordAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockForgotPasswordAuthRepository();
  });

  group('ForgotPasswordScreen Tests', () {
    testWidgets('renders all UI components matching reference design', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableForgotPasswordScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      // Top back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Centered Brand Logo
      final logoFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/amarnath_enterprise_client_app_logo.png',
      );
      expect(logoFinder, findsOneWidget);

      // "Forgot Password?" heading
      final headingFinder = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Forgot Password?'),
      );
      expect(headingFinder, findsOneWidget);

      // Subtitle
      expect(
        find.text(
          'No worries! Enter your mobile number\nand we’ll send you an OTP to reset your password.',
        ),
        findsOneWidget,
      );

      // Mobile Number Field
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Enter your mobile number'), findsOneWidget);
      expect(find.byIcon(Icons.phone_android_outlined), findsOneWidget);

      // Send OTP button
      expect(find.text('Send OTP'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('triggers onBack callback when back button is tapped', (
      WidgetTester tester,
    ) async {
      bool backTapped = false;
      await tester.pumpWidget(
        _createTestableForgotPasswordScreen(
          authRepository: mockRepo,
          onBack: () => backTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pump();

      expect(backTapped, isTrue);
    });

    testWidgets('validates empty mobile number', (WidgetTester tester) async {
      await tester.pumpWidget(
        _createTestableForgotPasswordScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      final sendOtpBtn = find.text('Send OTP');
      await tester.ensureVisible(sendOtpBtn);
      await tester.tap(sendOtpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your mobile number'), findsOneWidget);
      expect(mockRepo.sendOtpCalled, isFalse);
    });

    testWidgets('validates invalid mobile number (less than 10 digits)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableForgotPasswordScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      final mobileField = find.byType(EditableText);
      await tester.enterText(mobileField, '98765');
      await tester.pump();

      final sendOtpBtn = find.text('Send OTP');
      await tester.ensureVisible(sendOtpBtn);
      await tester.tap(sendOtpBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid 10-digit Indian mobile number.'),
        findsOneWidget,
      );
      expect(mockRepo.sendOtpCalled, isFalse);
    });

    testWidgets('validates mobile number not starting with 6-9', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableForgotPasswordScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      final mobileField = find.byType(EditableText);
      await tester.enterText(mobileField, '1234567890');
      await tester.pump();

      final sendOtpBtn = find.text('Send OTP');
      await tester.ensureVisible(sendOtpBtn);
      await tester.tap(sendOtpBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid 10-digit Indian mobile number.'),
        findsOneWidget,
      );
      expect(mockRepo.sendOtpCalled, isFalse);
    });

    testWidgets('submits valid mobile number and shows OTP Sent dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _createTestableForgotPasswordScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      final mobileField = find.byType(EditableText);
      await tester.enterText(mobileField, '9876543210');
      await tester.pump();

      final sendOtpBtn = find.text('Send OTP');
      await tester.ensureVisible(sendOtpBtn);
      await tester.tap(sendOtpBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.sendOtpCalled, isTrue);
      expect(mockRepo.lastMobile, '9876543210');

      // Check OTP Sent Dialog
      expect(find.text('OTP Sent'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('OTP Sent'), findsNothing);
    });

    testWidgets('triggers onOtpSent callback when provided', (
      WidgetTester tester,
    ) async {
      String? receivedVerificationId;
      String? receivedMobile;

      await tester.pumpWidget(
        _createTestableForgotPasswordScreen(
          authRepository: mockRepo,
          onOtpSent: (vId, mobile) {
            receivedVerificationId = vId;
            receivedMobile = mobile;
          },
        ),
      );
      await tester.pumpAndSettle();

      final mobileField = find.byType(EditableText);
      await tester.enterText(mobileField, '9876543210');
      await tester.pump();

      final sendOtpBtn = find.text('Send OTP');
      await tester.ensureVisible(sendOtpBtn);
      await tester.tap(sendOtpBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.sendOtpCalled, isTrue);
      expect(receivedVerificationId, 'test_verification_id_123');
      expect(receivedMobile, '9876543210');
      expect(find.text('OTP Sent'), findsNothing);
    });

    testWidgets('displays error SnackBar when verification fails', (
      WidgetTester tester,
    ) async {
      mockRepo.verificationFailedMessage =
          'Too many OTP requests. Please wait before trying again.';

      await tester.pumpWidget(
        _createTestableForgotPasswordScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      final mobileField = find.byType(EditableText);
      await tester.enterText(mobileField, '9876543210');
      await tester.pump();

      final sendOtpBtn = find.text('Send OTP');
      await tester.ensureVisible(sendOtpBtn);
      await tester.tap(sendOtpBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.sendOtpCalled, isTrue);
      expect(
        find.text('Too many OTP requests. Please wait before trying again.'),
        findsOneWidget,
      );
    });

    testWidgets('displays error SnackBar when repository throws exception', (
      WidgetTester tester,
    ) async {
      mockRepo.exceptionToThrow = Exception('Network error occurred');

      await tester.pumpWidget(
        _createTestableForgotPasswordScreen(authRepository: mockRepo),
      );
      await tester.pumpAndSettle();

      final mobileField = find.byType(EditableText);
      await tester.enterText(mobileField, '9876543210');
      await tester.pump();

      final sendOtpBtn = find.text('Send OTP');
      await tester.ensureVisible(sendOtpBtn);
      await tester.tap(sendOtpBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.sendOtpCalled, isTrue);
      expect(find.text('Exception: Network error occurred'), findsOneWidget);
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
            _createTestableForgotPasswordScreen(authRepository: mockRepo),
          );
          await tester.pump();

          final err = tester.takeException();
          expect(err, isNull);
          expect(find.byType(ForgotPasswordScreen), findsOneWidget);
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
