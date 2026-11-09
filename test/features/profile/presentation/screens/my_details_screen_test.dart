import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/profile/presentation/screens/my_details_screen.dart';

class MockDetailsAuthRepo implements AuthRepository {
  ClientModel? profile = const ClientModel(
    id: 'c1',
    name: 'Ramesh Patel',
    mobile: '9876543210',
    companyName: 'Patel Hardware',
    address: 'Shop No. 12, Market Yard, Rajkot',
    createdAt: '2026-11-01T10:00:00Z',
    updatedAt: '2026-11-01T10:00:00Z',
  );

  bool updateProfileCalled = false;
  String? updatedName;
  String? updatedCompany;
  String? updatedAddress;

  @override
  Future<ClientModel?> getCurrentClientProfile() async => profile;

  @override
  Future<void> updateClientProfile({
    required String name,
    required String companyName,
    required String address,
  }) async {
    updateProfileCalled = true;
    updatedName = name;
    updatedCompany = companyName;
    updatedAddress = address;
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

Widget _buildTestableMyDetailsScreen(AuthRepository repo) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        home: MyDetailsScreen(authRepository: repo),
      );
    },
  );
}

void main() {
  group('MyDetailsScreen Widget Tests', () {
    late MockDetailsAuthRepo repo;

    setUp(() {
      repo = MockDetailsAuthRepo();
    });

    testWidgets('populates initial client fields and saves changes', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestableMyDetailsScreen(repo));
      await tester.pumpAndSettle();

      expect(find.text('My Details'), findsOneWidget);
      expect(find.text('Ramesh Patel'), findsOneWidget);
      expect(find.text('Patel Hardware'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('Shop No. 12, Market Yard, Rajkot'), findsOneWidget);

      // Modify address
      final addressField = find.widgetWithText(
        TextFormField,
        'Shop No. 12, Market Yard, Rajkot',
      );
      await tester.enterText(addressField, 'New Shop 45, Rajkot');
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(repo.updateProfileCalled, isTrue);
      expect(repo.updatedAddress, 'New Shop 45, Rajkot');
    });
  });
}
