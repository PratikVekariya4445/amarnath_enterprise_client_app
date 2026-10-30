import 'package:flutter/material.dart';

/// Centralized color palette and styling constants for the Amarnath Enterprise Client App.
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primaryDarkGreen = Color(0xFF075C3F);
  static const Color secondaryGreen = Color(0xFF176B4D);
  static const Color brandTrackColor = Color(0x26075C3F);

  // Typography Colors
  static const Color textDark = Color(0xFF17232B);
  static const Color textSecondary = Color(0xFF737D86);
  static const Color textPlaceholder = Color(0xFFA0AAB2);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Surface & Input Colors
  static const Color inputBackground = Color(0xFFF5F8F6);
  static const Color inputBorder = Color(0xFFE1EAE4);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE1EAE4);
  static const Color signUpBoxBorder = Color(0xFFD0E5D9);
  static const Color signUpBoxBackground = Color(0x55F5F8F6);

  // Gradients
  static const LinearGradient loginButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryDarkGreen, secondaryGreen],
  );

  // Status Colors
  static const Color statusApproved = Color(0xFF075C3F);
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusRejected = Color(0xFFDC2626);
}
