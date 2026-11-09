import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/screens/change_password_screen.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/screens/my_details_screen.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/green_wave_header.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/logout_progress_dialog.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/widgets/profile_info_card.dart';

class MockProfileAuthRepo implements AuthRepository {
  ClientModel? profile = const ClientModel(
    id: 'c1',
    name: 'Ramesh Patel',
    mobile: '9876543210',
    companyName: 'Patel Hardware',
    address: 'Shop No. 12, Market Yard, Rajkot',
    createdAt: '2026-11-01T10:00:00Z',
    updatedAt: '2026-11-01T10:00:00Z',
  );

  bool signOutCalled = false;
  bool throwOnSignOut = false;
  Completer<void>? signOutCompleter;

  @override
  Future<ClientModel?> getCurrentClientProfile() async => profile;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    if (throwOnSignOut) {
      throw Exception('Simulated signOut failure');
    }
    if (signOutCompleter != null) {
      await signOutCompleter!.future;
    }
  }

  @override
  Future<void> updateClientProfile({
    required String name,
    required String companyName,
    required String address,
  }) async {
    profile = ClientModel(
      id: profile!.id,
      name: name,
      mobile: profile!.mobile,
      companyName: companyName,
      address: address,
      createdAt: profile!.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

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
  Future<User?> getCurrentApprovedClient() async => null;

  @override
  Future<SessionValidationResult> validateStartupSession() async {
    return const SessionValidationResult(status: SessionStatus.approved);
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
  Future<void> saveRememberMe({required bool remember, required String mobile}) async {}

  @override
  Future<({bool remember, String mobile})> getRememberMe() async => (remember: false, mobile: '');

  @override
  Future<String> getOwnerContactNumber() async => '+919876543210';
}

Widget _buildTestableProfileScreen({
  required AuthRepository authRepository,
  ClientModel? initialProfile,
  bool embedded = false,
  VoidCallback? onSignOut,
  Map<String, WidgetBuilder>? routes,
}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        routes: routes ?? const {},
        home: ProfileScreen(
          authRepository: authRepository,
          initialProfile: initialProfile,
          embedded: embedded,
          onSignOut: onSignOut,
        ),
      );
    },
  );
}

void main() {
  group('ProfileScreen Widget Tests', () {
    late MockProfileAuthRepo authRepo;

    setUp(() {
      authRepo = MockProfileAuthRepo();
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

      await tester.pumpWidget(
        _buildTestableProfileScreen(authRepository: authRepo),
      );
      await tester.pumpAndSettle();

      // 1. Green Wave Header & Title
      expect(find.byType(GreenWaveHeader), findsOneWidget);
      expect(find.text('Profile'), findsWidgets);

      // 2. Profile Info Card
      expect(find.byType(ProfileInfoCard), findsOneWidget);
      expect(find.text('Ramesh Patel'), findsOneWidget);
      expect(find.text('Patel Hardware'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

      // 3. My Details Card
      expect(find.text('My Details'), findsOneWidget);
      expect(
        find.text(
          'View and update your profile,\nbusiness address and other information',
        ),
        findsOneWidget,
      );

      // 4. Change Password Card
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Update your account password'), findsOneWidget);

      // 5. Logout Button
      expect(find.text('Logout'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('tapping Edit Profile navigates to MyDetailsScreen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestableProfileScreen(authRepository: authRepo),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(MyDetailsScreen), findsOneWidget);
      expect(find.text('Business / Delivery Address'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('tapping Change Password navigates to ChangePasswordScreen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestableProfileScreen(authRepository: authRepo),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordScreen), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('tapping Logout shows confirmation dialog and invokes signOut', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool signedOut = false;
      await tester.pumpWidget(
        _buildTestableProfileScreen(
          authRepository: authRepo,
          onSignOut: () {
            signedOut = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Are you sure you want to log out of your account?'),
        findsOneWidget,
      );

      // Tap Logout button inside dialog
      final dialogLogoutBtn = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text('Logout'),
      );
      await tester.tap(dialogLogoutBtn);
      await tester.pumpAndSettle();

      expect(signedOut, isTrue);
    });

    testWidgets(
      'tapping Cancel in Logout confirmation dialog closes dialog and does nothing',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestableProfileScreen(
            authRepository: authRepo,
            routes: {
              '/login': (context) => const SizedBox(),
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        // Tap Cancel
        final cancelBtn = find.descendant(
          of: find.byType(TextButton),
          matching: find.text('Cancel'),
        );
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();

        // Confirmation dialog is closed
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(LogoutProgressDialog), findsNothing);
        expect(authRepo.signOutCalled, isFalse);
      },
    );

    testWidgets(
      'confirming Logout immediately displays full-screen LogoutProgressDialog with green indicator and text',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final completer = Completer<void>();
        authRepo.signOutCompleter = completer;

        await tester.pumpWidget(
          _buildTestableProfileScreen(
            authRepository: authRepo,
            routes: {
              '/login': (context) => const SizedBox(),
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        final dialogLogoutBtn = find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.text('Logout'),
        );
        await tester.tap(dialogLogoutBtn);

        // Pump frame to mount the progress dialog while signOut is still pending
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Progress dialog must be visible
        expect(find.byType(LogoutProgressDialog), findsOneWidget);
        expect(find.text('Logging out...'), findsOneWidget);

        final textWidget = tester.widget<Text>(find.text('Logging out...'));
        expect(textWidget.style?.color, const Color(0xFF00864D));
        expect(textWidget.style?.fontWeight, FontWeight.w600);

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(
          indicator.valueColor?.value,
          const Color(0xFF00864D),
        );

        // Verify PopScope blocks back navigation
        final popScope = tester.widget<PopScope>(
          find.descendant(
            of: find.byType(LogoutProgressDialog),
            matching: find.byType(PopScope),
          ),
        );
        expect(popScope.canPop, isFalse);

        // Now complete the signOut operation
        completer.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Once complete, progress dialog is dismissed
        expect(find.byType(LogoutProgressDialog), findsNothing);
      },
    );

    testWidgets(
      'standalone Logout navigates to /login route after progress dialog finishes',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool loginRouteMounted = false;
        await tester.pumpWidget(
          _buildTestableProfileScreen(
            authRepository: authRepo,
            routes: {
              '/login': (context) {
                loginRouteMounted = true;
                return const Scaffold(body: Text('LOGIN_SCREEN_LANDING'));
              },
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        final dialogLogoutBtn = find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.text('Logout'),
        );
        await tester.tap(dialogLogoutBtn);
        await tester.pumpAndSettle();

        expect(authRepo.signOutCalled, isTrue);
        expect(loginRouteMounted, isTrue);
        expect(find.text('LOGIN_SCREEN_LANDING'), findsOneWidget);
      },
    );

    testWidgets(
      'logout error dismisses LogoutProgressDialog and shows error SnackBar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        authRepo.throwOnSignOut = true;

        await tester.pumpWidget(
          _buildTestableProfileScreen(
            authRepository: authRepo,
            routes: {
              '/login': (context) => const SizedBox(),
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        final dialogLogoutBtn = find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.text('Logout'),
        );
        await tester.tap(dialogLogoutBtn);
        await tester.pumpAndSettle();

        // Progress dialog should be dismissed
        expect(find.byType(LogoutProgressDialog), findsNothing);

        // Meaningful error message should be displayed
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Failed to log out'), findsOneWidget);
      },
    );
  });
}
