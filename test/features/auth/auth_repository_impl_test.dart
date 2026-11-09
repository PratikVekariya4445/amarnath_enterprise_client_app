import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:amarnath_enterprise_client_app/core/utils/mobile_number_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/repositories/auth_repository_impl.dart';

class FakeUser implements User {
  FakeUser({required this.uid, this.email});

  @override
  final String uid;

  @override
  final String? email;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserCredential implements UserCredential {
  FakeUserCredential({required this.user});

  @override
  final User user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthRemoteDataSource extends AuthRemoteDataSource {
  String? lastCreatedEmail;
  String? lastCreatedPassword;
  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastPasswordResetEmail;

  List<String> signInCalls = [];

  Map<String, dynamic>? lastUserRecord;
  Map<String, dynamic>? lastClientRecord;
  Map<String, dynamic>? lastSignupRequestRecord;

  FirebaseAuthException? signInExceptionToThrow;
  bool returnValidClientRecord = true;

  @override
  bool get isFirebaseAvailable => true;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    lastCreatedEmail = email;
    lastCreatedPassword = password;
    return FakeUserCredential(
      user: FakeUser(uid: 'mock_uid_123', email: email),
    );
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls.add(email);
    lastSignInEmail = email;
    lastSignInPassword = password;

    if (signInExceptionToThrow != null) {
      if (email.endsWith('@amarnath-enterprise-client.app')) {
        throw signInExceptionToThrow!;
      }
    }

    return FakeUserCredential(
      user: FakeUser(uid: 'mock_uid_123', email: email),
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    lastPasswordResetEmail = email;
  }

  @override
  Future<void> writeRegistrationRecords({
    required String uid,
    required Map<String, dynamic> userRecord,
    required Map<String, dynamic> clientRecord,
    required Map<String, dynamic> signupRequestRecord,
  }) async {
    lastUserRecord = userRecord;
    lastClientRecord = clientRecord;
    lastSignupRequestRecord = signupRequestRecord;
  }

  @override
  Future<Map<String, dynamic>?> readUserRecord(String uid) async {
    if (!returnValidClientRecord) return null;
    return {
      'role': 'client',
      'status': 'approved',
      'mobile': '8469800185',
    };
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  group('AuthRepositoryImpl Email Convention & Auth Tests', () {
    test('registerClient generates @amarnath-enterprise-client.app email format', () async {
      final mockDataSource = MockAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(dataSource: mockDataSource);

      await repository.registerClient(
        name: 'Monika Patel',
        shopName: 'Patel Electronics',
        mobile: '8469800185',
        address: '123 Station Road',
        password: 'securePassword123',
      );

      // Verify Firebase Auth user was created with new Client email format
      expect(
        mockDataSource.lastCreatedEmail,
        '8469800185@amarnath-enterprise-client.app',
      );
      expect(mockDataSource.lastCreatedPassword, 'securePassword123');

      // Verify client profile and signup request database records contain the same client email
      expect(
        mockDataSource.lastClientRecord?['email'],
        '8469800185@amarnath-enterprise-client.app',
      );
      expect(
        mockDataSource.lastSignupRequestRecord?['email'],
        '8469800185@amarnath-enterprise-client.app',
      );
      expect(mockDataSource.lastUserRecord?['role'], 'client');
      expect(mockDataSource.lastUserRecord?['status'], 'pending');
    });

    test('loginWithMobileAndPassword logs in with Client email format', () async {
      final mockDataSource = MockAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(dataSource: mockDataSource);

      final user = await repository.loginWithMobileAndPassword(
        mobile: '+91 84698 00185',
        password: 'securePassword123',
      );

      expect(user.uid, 'mock_uid_123');
      expect(
        mockDataSource.lastSignInEmail,
        '8469800185@amarnath-enterprise-client.app',
      );
      expect(mockDataSource.signInCalls, [
        '8469800185@amarnath-enterprise-client.app',
      ]);
    });

    test('loginWithMobileAndPassword falls back to legacy email for existing client accounts', () async {
      final mockDataSource = MockAuthRemoteDataSource()
        ..signInExceptionToThrow = FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user record found for given email.',
        );
      final repository = AuthRepositoryImpl(dataSource: mockDataSource);

      final user = await repository.loginWithMobileAndPassword(
        mobile: '8469800185',
        password: 'securePassword123',
      );

      expect(user.uid, 'mock_uid_123');
      // Verify first tried the client email, then fell back to legacy email
      expect(mockDataSource.signInCalls, [
        '8469800185@amarnath-enterprise-client.app',
        '8469800185@amarnath-enterprise.app',
      ]);
      expect(
        mockDataSource.lastSignInEmail,
        '8469800185@amarnath-enterprise.app',
      );
    });

    test('sendPasswordResetEmailForClient generates Client email format', () async {
      final mockDataSource = MockAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(dataSource: mockDataSource);

      await repository.sendPasswordResetEmailForClient(
        mobile: '+91 84698-00185',
      );

      expect(
        mockDataSource.lastPasswordResetEmail,
        '8469800185@amarnath-enterprise-client.app',
      );
    });

    test('verifies Owner and Client conventions are strictly separate', () {
      const mobile = '8469800185';
      final ownerEmail = MobileNumberUtils.generateOwnerAuthEmail(mobile);
      final clientEmail = MobileNumberUtils.generateClientAuthEmail(mobile);

      expect(ownerEmail, '8469800185@amarnath-enterprise.app');
      expect(clientEmail, '8469800185@amarnath-enterprise-client.app');
      expect(ownerEmail, isNot(equals(clientEmail)));
    });
  });
}
