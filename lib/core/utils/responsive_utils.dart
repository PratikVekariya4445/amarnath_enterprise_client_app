import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';

// Re-export sizer primitives so files can access Device, Sizer, ScreenType, etc.
// while hiding the flawed SizerExt to prevent ambiguous extension conflicts.
export 'package:sizer/sizer.dart' hide SizerExt;

/// Safe, bounded responsive extension on [num].
///
/// Converts values into responsive device-independent pixels (.dp) based on
/// a standard mobile reference width (390 logical pixels).
extension ResponsiveNum on num {
  /// Responsive device-independent pixels (dp).
  double get dp {
    if (!kIsWeb) {
      try {
        if (Platform.environment.containsKey('FLUTTER_TEST')) {
          return toDouble();
        }
      } catch (_) {}
    }

    try {
      final width = Device.width;
      if (width <= 0) return toDouble();
      const double referenceWidth = 390.0;
      final double scale = (width / referenceWidth).clamp(0.85, 1.25);
      return toDouble() * scale;
    } catch (_) {
      return toDouble();
    }
  }

  /// Responsive scalable pixels (sp) for font sizing.
  double get sp => dp;

  /// Width percentage of screen.
  double get w {
    try {
      return toDouble() * (Device.width / 100);
    } catch (_) {
      return toDouble();
    }
  }

  /// Height percentage of screen.
  double get h {
    try {
      return toDouble() * (Device.height / 100);
    } catch (_) {
      return toDouble();
    }
  }
}
