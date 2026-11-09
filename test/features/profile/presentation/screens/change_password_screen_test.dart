import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amarnath_enterprise_client_app/core/errors/auth_error_mapper.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/screens/change_password_screen.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/change_password_bottom_waves.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/security_shield_illustration.dart';

class MockPasswordAuthRepo implements AuthRepository {
  bool updatePasswordCalled = false;
  String? updatedCurrent;
  String? updatedNew;
  bool shouldThrowError = false;
  String errorMessage = 'The current password entered is incorrect.';
  String errorCode = '';

  bool sendOtpCalled = false;
  bool verifyOtpCalled = false;
  bool resetWithPhoneCalled = false;
  String? lastResetMobile;
  String? lastResetPassword;
  bool failSessionRestoration = false;

  ClientModel? mockProfile = const ClientModel(
    id: 'c1',
    name: 'Ramesh Patel',
    mobile: '9876543210',
    companyName: 'Patel Hardware',
    createdAt: '2026-11-01T10:00:00Z',
    updatedAt: '2026-11-01T10:00:00Z',
  );

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (shouldThrowError) {
      throw AuthException(errorMessage, code: errorCode);
    }
    updatePasswordCalled = true;
    updatedCurrent = currentPassword;
    updatedNew = newPassword;
  }

  @override
  Future<ClientModel?> getCurrentClientProfile() async => mockProfile;

  @override
  Future<void> updateClientProfile({
    required String name,
    required String companyName,
    required String address,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<User?> getCurrentApprovedClient() async => null;

  @override
  Future<SessionValidationResult> validateStartupSession() async {
    return const SessionValidationResult(status: SessionStatus.approved);
  }

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
  Future<void> sendPasswordResetOtp({
    required String mobile,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    void Function(PhoneAuthCredential credential)? onVerificationCompleted,
    int? forceResendingToken,
  }) async {
    sendOtpCalled = true;
    onCodeSent('test_verification_id', 12345);
  }

  @override
  Future<PhoneAuthCredential> verifyPasswordResetOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    verifyOtpCalled = true;
    if (smsCode == '000000') {
      throw const AuthException(
          'The entered OTP is incorrect. Please verify and try again.');
    }
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  @override
  Future<void> resetClientPasswordWithVerifiedPhone({
    required String mobile,
    required String newPassword,
  }) async {
    resetWithPhoneCalled = true;
    lastResetMobile = mobile;
    lastResetPassword = newPassword;
    if (failSessionRestoration) {
      throw const ClientSessionRestorationException();
    }
  }

  @override
  Future<void> saveRememberMe(
      {required bool remember, required String mobile}) async {}

  @override
  Future<({bool remember, String mobile})> getRememberMe() async =>
      (remember: false, mobile: '');

  @override
  Future<String> getOwnerContactNumber() async => '+919876543210';
}

Widget _buildTestableChangePasswordScreen(AuthRepository repo) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        routes: {
          '/login': (context) => const Scaffold(body: Text('Login Screen')),
        },
        home: ChangePasswordScreen(authRepository: repo),
      );
    },
  );
}

void main() {
  group('ChangePasswordScreen UI & Interaction Tests', () {
    late MockPasswordAuthRepo repo;

    setUp(() {
      repo = MockPasswordAuthRepo();
    });

    testWidgets('renders all visual elements matching reference design', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestableChangePasswordScreen(repo));
      await tester.pumpAndSettle();

      // 1. Top App Bar
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // 2. Security Shield Illustration
      expect(find.byType(SecurityShieldIllustration), findsOneWidget);

      // 3. Bottom Decorative Waves
      expect(find.byType(ChangePasswordBottomWaves), findsOneWidget);

      // 4. Form Labels
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      // 5. Input Fields with Hints
      expect(find.widgetWithText(TextFormField, 'Enter current password'),
          findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Enter new password'),
          findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirm new password'),
          findsOneWidget);

      // 6. Password Requirement Information Banner
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.text('Password must be at least 6 characters long.'),
          findsOneWidget);

      // 7. Update Password Button
      expect(find.widgetWithText(ElevatedButton, 'Update Password'),
          findsOneWidget);

      // 8. Lock icon and visibility icon
      expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(3));
    });

    testWidgets('toggles visibility independently for each password field', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestableChangePasswordScreen(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(3));
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Tap first eye icon
      final firstEye = find.byIcon(Icons.visibility_off_outlined).first;
      await tester.tap(firstEye);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));
    });

    testWidgets('Scenario A: Normal change password with correct current password succeeds', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestableChangePasswordScreen(repo));
      await tester.pumpAndSettle();

      final currentField =
          find.widgetWithText(TextFormField, 'Enter current password');
      final newField =
          find.widgetWithText(TextFormField, 'Enter new password');
      final confirmField =
          find.widgetWithText(TextFormField, 'Confirm new password');

      await tester.enterText(currentField, 'oldPass123');
      await tester.enterText(newField, 'newPass123');
      await tester.enterText(confirmField, 'newPass123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pump();
      await tester.pump();

      expect(repo.updatePasswordCalled, isTrue);
      expect(repo.updatedCurrent, 'oldPass123');
      expect(repo.updatedNew, 'newPass123');
      expect(find.text('Password updated successfully.'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Scenario B & C: Incorrect current password shows dialog, Cancel returns to initial form',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repo.shouldThrowError = true;
      repo.errorCode = 'wrong-password';
      repo.errorMessage = 'Incorrect password. Please verify and try again.';

      await tester.pumpWidget(_buildTestableChangePasswordScreen(repo));
      await tester.pumpAndSettle();

      final currentField =
          find.widgetWithText(TextFormField, 'Enter current password');
      final newField =
          find.widgetWithText(TextFormField, 'Enter new password');
      final confirmField =
          find.widgetWithText(TextFormField, 'Confirm new password');

      await tester.enterText(currentField, 'wrongPassword');
      await tester.enterText(newField, 'newPass123');
      await tester.enterText(confirmField, 'newPass123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pumpAndSettle();

      // Verify Incorrect Password dialog appears
      expect(find.text('Incorrect Password'), findsOneWidget);
      expect(
          find.text(
              'Your current password is incorrect. Would you like to reset your password using OTP verification?'),
          findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reset Password'),
          findsOneWidget);

      // Scenario C: Tap Cancel
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Verifies dialog closed and returns to initial form
      expect(find.text('Incorrect Password'), findsNothing);
      expect(find.text('Current Password'), findsOneWidget);
    });

    testWidgets(
        'Scenario D to J: Full OTP reset flow (Mobile -> Send OTP -> Enter OTP -> New Password -> Cloud Function Reset)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repo.shouldThrowError = true;
      repo.errorCode = 'invalid-credential';
      repo.errorMessage = 'The current password entered is incorrect.';

      await tester.pumpWidget(_buildTestableChangePasswordScreen(repo));
      await tester.pumpAndSettle();

      // Trigger incorrect password
      final currentField =
          find.widgetWithText(TextFormField, 'Enter current password');
      final newField =
          find.widgetWithText(TextFormField, 'Enter new password');
      final confirmField =
          find.widgetWithText(TextFormField, 'Confirm new password');

      await tester.enterText(currentField, 'wrongPass');
      await tester.enterText(newField, 'newPass123');
      await tester.enterText(confirmField, 'newPass123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pumpAndSettle();

      // Scenario D: Tap "Reset Password" inside dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
      await tester.pumpAndSettle();

      // Registered mobile screen appears
      expect(find.text('Reset Password via OTP'), findsOneWidget);
      expect(find.text('Registered Mobile Number'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Send OTP'), findsOneWidget);

      // Scenario E: Tap "Send OTP"
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
      await tester.pumpAndSettle();

      expect(repo.sendOtpCalled, isTrue);
      // OTP verification screen appears
      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.text('6-Digit OTP'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Verify OTP'), findsOneWidget);

      // Scenario F: Enter incorrect OTP code (000000)
      final otpField = find.byType(TextFormField).first;
      await tester.enterText(otpField, '000000');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
      await tester.pumpAndSettle();

      expect(
          find.text('The entered OTP is incorrect. Please verify and try again.'),
          findsOneWidget);

      // Scenario G: Enter correct OTP code (123456)
      await tester.enterText(otpField, '123456');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
      await tester.pumpAndSettle();

      expect(repo.verifyOtpCalled, isTrue);
      // Set New Password view appears (Current Password field must NOT be displayed!)
      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('Current Password'), findsNothing);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Update Password'),
          findsOneWidget);

      // Scenario H: Password mismatch test
      final otpNewField =
          find.widgetWithText(TextFormField, 'Enter new password');
      final otpConfirmField =
          find.widgetWithText(TextFormField, 'Confirm new password');

      await tester.enterText(otpNewField, 'mySecretPass1');
      await tester.enterText(otpConfirmField, 'mySecretPass2');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);

      // Scenario I & J: Valid new password and password match -> reset & session restore succeeds
      await tester.enterText(otpConfirmField, 'mySecretPass1');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repo.resetWithPhoneCalled, isTrue);
      expect(repo.lastResetMobile, '9876543210');
      expect(repo.lastResetPassword, 'mySecretPass1');
      expect(find.text('Password updated successfully.'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Scenario K: Non-credential error (e.g. network failure) shows SnackBar directly without OTP dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repo.shouldThrowError = true;
      repo.errorCode = 'network-request-failed';
      repo.errorMessage =
          'Unable to connect. Please check your internet connection.';

      await tester.pumpWidget(_buildTestableChangePasswordScreen(repo));
      await tester.pumpAndSettle();

      final currentField =
          find.widgetWithText(TextFormField, 'Enter current password');
      final newField =
          find.widgetWithText(TextFormField, 'Enter new password');
      final confirmField =
          find.widgetWithText(TextFormField, 'Confirm new password');

      await tester.enterText(currentField, 'anyOldPass');
      await tester.enterText(newField, 'newPass123');
      await tester.enterText(confirmField, 'newPass123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pumpAndSettle();

      // No Incorrect Password dialog
      expect(find.text('Incorrect Password'), findsNothing);
      // SnackBar shows network error
      expect(
          find.text('Unable to connect. Please check your internet connection.'),
          findsOneWidget);
    });

    testWidgets(
        'Scenario L: Cloud Function updates password but session restoration fails displays dialog to login',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      repo.shouldThrowError = true;
      repo.errorCode = 'wrong-password';
      repo.errorMessage = 'Incorrect password.';
      repo.failSessionRestoration = true;

      await tester.pumpWidget(_buildTestableChangePasswordScreen(repo));
      await tester.pumpAndSettle();

      // Trigger incorrect password
      final currentField =
          find.widgetWithText(TextFormField, 'Enter current password');
      final newField =
          find.widgetWithText(TextFormField, 'Enter new password');
      final confirmField =
          find.widgetWithText(TextFormField, 'Confirm new password');

      await tester.enterText(currentField, 'wrong');
      await tester.enterText(newField, 'newPass123');
      await tester.enterText(confirmField, 'newPass123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pumpAndSettle();

      // Reset password dialog -> Send OTP -> Verify OTP
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
      await tester.pumpAndSettle();

      final otpField = find.byType(TextFormField).first;
      await tester.enterText(otpField, '123456');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
      await tester.pumpAndSettle();

      final otpNewField =
          find.widgetWithText(TextFormField, 'Enter new password');
      final otpConfirmField =
          find.widgetWithText(TextFormField, 'Confirm new password');

      await tester.enterText(otpNewField, 'mySecretPass1');
      await tester.enterText(otpConfirmField, 'mySecretPass1');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pumpAndSettle();

      // Verify Password Updated dialog appears with Go to Login button
      expect(find.text('Password Updated'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Go to Login'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Go to Login'));
      await tester.pumpAndSettle();

      // Navigated to login
      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
