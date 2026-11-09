import 'package:firebase_auth/firebase_auth.dart';
import 'package:amarnath_enterprise_client_app/features/auth/data/models/client_model.dart';

enum SessionStatus {
  approved,
  pending,
  rejected,
  owner,
  unauthenticated,
  invalid,
}

class SessionValidationResult {
  const SessionValidationResult({
    required this.status,
    this.user,
    this.message,
  });

  final SessionStatus status;
  final User? user;
  final String? message;

  bool get isApproved => status == SessionStatus.approved;
}

abstract class AuthRepository {
  /// Authenticates a client with mobile number and password.
  /// Validates that role == "client" and status == "approved".
  Future<User> loginWithMobileAndPassword({
    required String mobile,
    required String password,
  });

  /// Registers a new client with credentials and creates pending database records.
  Future<void> registerClient({
    required String name,
    required String shopName,
    required String mobile,
    required String address,
    required String password,
  });

  /// Sends a Firebase Phone Authentication OTP for password reset.
  Future<void> sendPasswordResetOtp({
    required String mobile,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    void Function(PhoneAuthCredential credential)? onVerificationCompleted,
    int? forceResendingToken,
  });

  /// Checks if a client is currently authenticated and approved.
  Future<User?> getCurrentApprovedClient();

  /// Validates the startup authentication session and returns a categorized result.
  Future<SessionValidationResult> validateStartupSession();

  /// Retrieves the authenticated client's full profile model.
  Future<ClientModel?> getCurrentClientProfile();

  /// Updates client profile information (name, shop/company name, address).
  Future<void> updateClientProfile({
    required String name,
    required String companyName,
    required String address,
  });

  /// Updates the authenticated client's password after verifying the current password.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Verifies the entered SMS OTP against Firebase Phone Auth and establishes the temporary phone session.
  Future<PhoneAuthCredential> verifyPasswordResetOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Resets client password via the trusted Cloud Function using the verified phone auth token,
  /// and restores the original Client email/password authentication session.
  Future<void> resetClientPasswordWithVerifiedPhone({
    required String mobile,
    required String newPassword,
  });

  /// Signs the current user out.
  Future<void> signOut();

  /// Saves remember-me preferences.
  Future<void> saveRememberMe({required bool remember, required String mobile});

  /// Retrieves saved remember-me preferences.
  Future<({bool remember, String mobile})> getRememberMe();

  /// Retrieves the official Owner contact phone number (dynamic or default).
  Future<String> getOwnerContactNumber();
}
