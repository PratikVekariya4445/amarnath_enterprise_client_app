/// Centralized Firebase Realtime Database paths for Amarnath Enterprise.
///
/// Strictly adheres to the root path 'amarntath_enterprise'.
class DatabasePaths {
  DatabasePaths._();

  /// Root node for all Amarnath Enterprise records.
  static const String root = 'amarntath_enterprise';

  /// Node for user account status and role records (`amarntath_enterprise/users`).
  static String get users => '$root/users';

  /// Specific user record path (`amarntath_enterprise/users/{uid}`).
  static String user(String uid) => '$users/$uid';

  /// Node for client accounts (`amarntath_enterprise/clients`).
  static String get clients => '$root/clients';

  /// Specific client record path (`amarntath_enterprise/clients/{clientId}`).
  static String client(String clientId) => '$clients/$clientId';

  /// Node for client signup requests (`amarntath_enterprise/signupRequests`).
  static String get signupRequests => '$root/signupRequests';

  /// Node for product catalog (`amarntath_enterprise/products`).
  static String get products => '$root/products';

  /// Node for orders placed by clients (`amarntath_enterprise/orders`).
  static String get orders => '$root/orders';
}
