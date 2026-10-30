import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amarnath_enterprise_client_app/core/errors/auth_error_mapper.dart';
import 'package:amarnath_enterprise_client_app/core/utils/mobile_number_utils.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:amarnath_enterprise_client_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    AuthRemoteDataSource? dataSource,
  }) : _dataSource = dataSource ?? AuthRemoteDataSource();

  final AuthRemoteDataSource _dataSource;

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

    final normalized = MobileNumberUtils.normalizeMobile(mobile);
    final generatedEmail = MobileNumberUtils.generateFirebaseEmail(normalized);

    try {
      final credential = await _dataSource.signInWithEmailAndPassword(
        email: generatedEmail,
        password: password,
      );

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
  Future<User?> getCurrentApprovedClient() async {
    if (!_dataSource.isFirebaseAvailable) return null;
    final user = _dataSource.currentUser;
    if (user == null) return null;

    try {
      final userRecord = await _dataSource.readUserRecord(user.uid);
      if (userRecord == null) return null;

      final role = (userRecord['role'] as String?)?.trim().toLowerCase() ?? '';
      final status =
          (userRecord['status'] as String?)?.trim().toLowerCase() ?? '';

      if (role == 'client' && status == 'approved') {
        return user;
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
}
