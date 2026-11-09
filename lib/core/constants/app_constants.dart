/// Application-wide constants for Amarnath Enterprise Client App.
class AppConstants {
  AppConstants._();

  /// Official Amarnath Enterprise Owner contact number for customer inquiries.
  /// Used for phone dialer and WhatsApp support.
  ///
  /// Format: E.164 (`+919876543210`) for dialer and WhatsApp.
  static const String ownerContactNumber = '+919876543210';

  /// Human-friendly formatted owner phone number for UI display.
  static const String ownerDisplayPhone = '+91 98765 43210';

  /// Pre-filled WhatsApp message sent by clients when asking about registration approval.
  static const String registrationInquiryMessage =
      'Hello, I have submitted my registration request for Amarnath Enterprise. Please help me with the approval status.';
}
