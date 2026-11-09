import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amarnath_enterprise_client_app/core/constants/app_constants.dart';
import 'package:amarnath_enterprise_client_app/core/errors/auth_error_mapper.dart';
import 'package:amarnath_enterprise_client_app/core/notifications/notification_service.dart';
import 'package:amarnath_enterprise_client_app/core/utils/mobile_number_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/signup_request_model.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/services/client_password_reset_backend_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    AuthRemoteDataSource? dataSource,
    ClientPasswordResetBackendService? backendService,
  })  : _dataSource = dataSource ?? AuthRemoteDataSource(),
        _backendService =
            backendService ?? DefaultClientPasswordResetBackendService();

  final AuthRemoteDataSource _dataSource;
  final ClientPasswordResetBackendService _backendService;

  static const String _prefRememberKey = 'pref_client_remember_me';
  static const String _prefMobileKey = 'pref_client_saved_mobile';

  @override
  Future<User> loginWithMobileAndPassword({
    required String mobile,
    required String password,
  }) async {
    final validationError = MobileNumberUtils.validateMobile(mobile);
    if (validationError != null) {
      throw AuthException(validationError);
    }

    if (password.trim().isEmpty) {
      throw const AuthException('Please enter your password.');
    }

    final normalized = MobileNumberUtils.normalizeMobileNumber(mobile);
    final clientEmail = MobileNumberUtils.generateClientAuthEmail(normalized);

    try {
      UserCredential credential;
      try {
        credential = await _dataSource.signInWithEmailAndPassword(
          email: clientEmail,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // Fallback for existing client accounts created with the previous email convention
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          final legacyEmail =
              MobileNumberUtils.generateLegacyClientAuthEmail(normalized);
          try {
            credential = await _dataSource.signInWithEmailAndPassword(
              email: legacyEmail,
              password: password,
            );
          } catch (_) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Authentication failed. No user found.');
      }

      // Validate user record in Realtime Database: amarntath_enterprise/users/{uid}
      final userRecord = await _dataSource.readUserRecord(user.uid);
      if (userRecord == null) {
        await _dataSource.signOut();
        throw const MissingUserRecordException();
      }

      final role = (userRecord['role'] as String?)?.trim().toLowerCase() ?? '';
      final status =
          (userRecord['status'] as String?)?.trim().toLowerCase() ?? '';

      // Verify role == "client"
      if (role != 'client') {
        await _dataSource.signOut();
        throw const ClientAccessDeniedException();
      }

      // Verify status == "approved"
      if (status != 'approved') {
        await _dataSource.signOut();
        throw ClientNotApprovedException(status.isEmpty ? 'pending' : status);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(AuthErrorMapper.mapFirebaseAuthException(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(AuthErrorMapper.mapCustomAuthError(e));
    }
  }

  @override
  Future<void> registerClient({
    required String name,
    required String shopName,
    required String mobile,
    required String address,
    required String password,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const AuthException('Please enter your full name.');
    }

    final cleanShopName = shopName.trim();
    if (cleanShopName.isEmpty) {
      throw const AuthException('Please enter your shop name.');
    }

    final validationError = MobileNumberUtils.validateMobile(mobile);
    if (validationError != null) {
      throw AuthException(validationError);
    }

    final cleanAddress = address.trim();
    if (cleanAddress.isEmpty) {
      throw const AuthException('Please enter your shop address.');
    }

    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }

    final normalizedMobile = MobileNumberUtils.normalizeMobileNumber(mobile);
    final generatedEmail =
        MobileNumberUtils.generateClientAuthEmail(normalizedMobile);

    try {
      // 1. Create user in Firebase Authentication
      final credential = await _dataSource.createUserWithEmailAndPassword(
        email: generatedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException(
          'Registration failed. Could not create account.',
        );
      }

      final nowIso = DateTime.now().toIso8601String();
      final nowMillis = DateTime.now().millisecondsSinceEpoch;

      // 2. Authorization record: amarntath_enterprise/users/{uid}
      final userRecord = {
        'role': 'client',
        'status': 'pending',
        'mobile': normalizedMobile,
        'createdAt': nowMillis,
        'updatedAt': nowMillis,
      };

      // 3. Client profile record: amarntath_enterprise/clients/{clientId}
      final clientModel = ClientModel(
        id: user.uid,
        name: cleanName,
        mobile: normalizedMobile,
        companyName: cleanShopName,
        address: cleanAddress,
        email: generatedEmail,
        isActive: false,
        createdAt: nowIso,
        updatedAt: nowIso,
      );

      // 4. Signup request record: amarntath_enterprise/signupRequests/{requestId}
      final signupRequestModel = SignupRequestModel(
        id: user.uid,
        name: cleanName,
        mobile: normalizedMobile,
        companyName: cleanShopName,
        address: cleanAddress,
        email: generatedEmail,
        status: 'pending',
        createdAt: nowIso,
        updatedAt: nowIso,
      );

      // 5. Atomic / Dual-engine database record write
      try {
        await _dataSource.writeRegistrationRecords(
          uid: user.uid,
          userRecord: userRecord,
          clientRecord: clientModel.toJson(),
          signupRequestRecord: signupRequestModel.toJson(),
        );
      } catch (dbError) {
        // Rollback partial registration: delete newly created auth user so account is not orphaned
        await _dataSource.deleteCurrentUser();
        throw const AuthException(
          'Failed to complete registration profile. Please try again.',
          code: 'db-write-failed',
        );
      }

      // 6. Sign out newly created pending user
      await _dataSource.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(AuthErrorMapper.mapFirebaseAuthException(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(AuthErrorMapper.mapCustomAuthError(e));
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
    final validationError = MobileNumberUtils.validateMobile(mobile);
    if (validationError != null) {
      throw AuthException(validationError);
    }

    final e164 = MobileNumberUtils.normalizeToE164(mobile);

    try {
      await _dataSource.verifyPhoneNumber(
        phoneNumber: e164,
        forceResendingToken: forceResendingToken,
        codeSent: (verificationId, resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(AuthErrorMapper.mapFirebaseAuthException(e));
        },
        verificationCompleted: (PhoneAuthCredential credential) {
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(AuthErrorMapper.mapFirebaseAuthException(e));
    } catch (e) {
      throw AuthException(AuthErrorMapper.mapCustomAuthError(e));
    }
  }

  @override
  Future<SessionValidationResult> validateStartupSession() async {
    if (!_dataSource.isFirebaseAvailable) {
      return const SessionValidationResult(
        status: SessionStatus.unauthenticated,
      );
    }

    final user = _dataSource.currentUser;
    if (user == null) {
      return const SessionValidationResult(
        status: SessionStatus.unauthenticated,
      );
    }

    try {
      final userRecord = await _dataSource.readUserRecord(user.uid);
      if (userRecord == null) {
        await _dataSource.signOut();
        return const SessionValidationResult(status: SessionStatus.invalid);
      }

      final role = (userRecord['role'] as String?)?.trim().toLowerCase() ?? '';
      final status =
          (userRecord['status'] as String?)?.trim().toLowerCase() ?? '';

      if (role == 'owner') {
        await _dataSource.signOut();
        return const SessionValidationResult(status: SessionStatus.owner);
      }

      if (role == 'client') {
        if (status == 'approved') {
          return SessionValidationResult(
            status: SessionStatus.approved,
            user: user,
          );
        } else if (status == 'pending') {
          await _dataSource.signOut();
          return const SessionValidationResult(
            status: SessionStatus.pending,
            message:
                'Your registration is still awaiting Owner approval. You can log in once your account has been approved.',
          );
        } else if (status == 'rejected') {
          await _dataSource.signOut();
          return const SessionValidationResult(
            status: SessionStatus.rejected,
            message:
                'Your registration request has not been approved. Please contact Amarnath Enterprise for assistance.',
          );
        }
      }

      await _dataSource.signOut();
      return const SessionValidationResult(status: SessionStatus.invalid);
    } catch (_) {
      await _dataSource.signOut();
      return const SessionValidationResult(status: SessionStatus.invalid);
    }
  }

  @override
  Future<User?> getCurrentApprovedClient() async {
    final result = await validateStartupSession();
    return result.isApproved ? result.user : null;
  }

  @override
  Future<ClientModel?> getCurrentClientProfile() async {
    if (!_dataSource.isFirebaseAvailable) return null;
    final user = _dataSource.currentUser;
    if (user == null) return null;

    try {
      final clientRecord = await _dataSource.readClientRecord(user.uid);
      if (clientRecord != null) {
        return ClientModel.fromJson(clientRecord, user.uid);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _dataSource.signOut();
  }

  @override
  Future<void> saveRememberMe({
    required bool remember,
    required String mobile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefRememberKey, remember);
      if (remember) {
        await prefs.setString(_prefMobileKey, mobile);
      } else {
        await prefs.remove(_prefMobileKey);
      }
    } catch (_) {}
  }

  @override
  Future<({bool remember, String mobile})> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_prefRememberKey) ?? false;
      final mobile = prefs.getString(_prefMobileKey) ?? '';
      return (remember: remember, mobile: mobile);
    } catch (_) {
      return (remember: false, mobile: '');
    }
  }

  @override
  Future<String> getOwnerContactNumber() async {
    try {
      final dynamicMobile = await _dataSource.getOwnerMobile();
      if (dynamicMobile != null && dynamicMobile.trim().isNotEmpty) {
        return MobileNumberUtils.normalizeToE164(dynamicMobile);
      }
    } catch (_) {}
    return AppConstants.ownerContactNumber;
  }

  @override
  Future<void> updateClientProfile({
    required String name,
    required String companyName,
    required String address,
  }) async {
    final user = _dataSource.currentUser;
    if (user == null) {
      throw const AuthException('No user is currently signed in.', code: 'no-user');
    }

    try {
      await _dataSource.updateClientProfile(
        uid: user.uid,
        name: name.trim(),
        companyName: companyName.trim(),
        address: address.trim(),
      );
    } catch (e) {
      throw AuthException('Failed to update profile: $e');
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _dataSource.currentUser;
    if (user == null) {
      throw const AuthException('No user is currently signed in.', code: 'no-user');
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const AuthException('User credentials could not be resolved.');
    }

    try {
      // Reauthenticate before updating password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await _dataSource.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(AuthErrorMapper.mapFirebaseAuthException(e), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(AuthErrorMapper.mapCustomAuthError(e));
    }
  }

  @override
  Future<PhoneAuthCredential> verifyPasswordResetOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final trimmedCode = smsCode.trim();
    if (trimmedCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(trimmedCode)) {
      throw const AuthException('Please enter a valid 6-digit OTP code.');
    }
    if (verificationId.trim().isEmpty) {
      throw const AuthException(
        'Verification session has expired. Please request a new OTP.',
        code: 'session-expired',
      );
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: trimmedCode,
      );
      await _dataSource.signInWithPhoneCredential(credential);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(AuthErrorMapper.mapFirebaseAuthException(e), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(AuthErrorMapper.mapCustomAuthError(e));
    }
  }

  @override
  Future<void> resetClientPasswordWithVerifiedPhone({
    required String mobile,
    required String newPassword,
  }) async {
    final normalized = MobileNumberUtils.normalizeMobileNumber(mobile);

    if (newPassword.isEmpty) {
      throw const AuthException('New password cannot be empty.');
    }
    if (newPassword.length < 6) {
      throw const AuthException(
        'Password must be at least 6 characters long.',
        code: 'weak-password',
      );
    }

    String? idToken;
    try {
      idToken = await _dataSource.currentUser?.getIdToken();
    } catch (_) {}

    if (idToken == null || idToken.isEmpty) {
      throw const AuthException(
        'Phone verification session has expired. Please verify your OTP again.',
        code: 'session-expired',
      );
    }

    // Step 7: Update password via deployed Cloud Function
    await _backendService.resetClientPassword(
      mobile: normalized,
      newPassword: newPassword,
      idToken: idToken,
    );

    // Step 8: Restore the Client authentication session
    // Sign out temporary Phone Auth user
    try {
      await _dataSource.signOut();
    } catch (_) {}

    // Sign in using original Client Email/Password convention
    final clientEmail = MobileNumberUtils.generateClientAuthEmail(normalized);
    try {
      final userCred = await _dataSource.signInWithEmailAndPassword(
        email: clientEmail,
        password: newPassword,
      );

      final clientUid = userCred.user?.uid;
      if (clientUid != null) {
        try {
          await NotificationService.instance.registerCurrentClientToken();
        } catch (_) {}
      }
    } catch (restoreError) {
      debugPrint('Client session restoration failed after password reset: $restoreError');
      throw const ClientSessionRestorationException(
        'Password was updated successfully, but session could not be restored automatically. Please log in with your new password.',
      );
    }
  }

  /// Sends a Firebase password reset email for the Client account associated with [mobile].
  /// Uses [MobileNumberUtils.generateClientAuthEmail].
  Future<void> sendPasswordResetEmailForClient({required String mobile}) async {
    final validationError = MobileNumberUtils.validateMobile(mobile);
    if (validationError != null) {
      throw AuthException(validationError);
    }
    final normalized = MobileNumberUtils.normalizeMobileNumber(mobile);
    final clientEmail = MobileNumberUtils.generateClientAuthEmail(normalized);

    try {
      await _dataSource.sendPasswordResetEmail(email: clientEmail);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        final legacyEmail =
            MobileNumberUtils.generateLegacyClientAuthEmail(normalized);
        try {
          await _dataSource.sendPasswordResetEmail(email: legacyEmail);
          return;
        } catch (_) {}
      }
      throw AuthException(AuthErrorMapper.mapFirebaseAuthException(e));
    } catch (e) {
      throw AuthException(AuthErrorMapper.mapCustomAuthError(e));
    }
  }

  /// Looks up whether an authentication account exists for the given [mobile].
  Future<bool> checkClientAccountExists({required String mobile}) async {
    final validationError = MobileNumberUtils.validateMobile(mobile);
    if (validationError != null) {
      return false;
    }
    final normalized = MobileNumberUtils.normalizeMobileNumber(mobile);
    return await _dataSource.checkUserExistsByMobile(normalized);
  }
}
