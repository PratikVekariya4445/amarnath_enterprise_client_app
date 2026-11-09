import 'package:flutter/material.dart';

/// Normalized Order Status enumeration for the Client App matching design specifications.
enum ClientOrderStatus {
  all(
    label: 'All',
    backgroundColor: Color(0xFF00864D),
    textColor: Colors.white,
    icon: Icons.list_alt_rounded,
  ),
  pending(
    label: 'Pending',
    backgroundColor: Color(0xFFFFF1BE),
    textColor: Color(0xFF86500B),
    icon: Icons.access_time_rounded,
  ),
  confirmed(
    label: 'Confirmed',
    backgroundColor: Color(0xFFD9F9E3),
    textColor: Color(0xFF006B30),
    icon: Icons.check_circle_rounded,
  ),
  inProcess(
    label: 'In Process',
    backgroundColor: Color(0xFFD9EEFF),
    textColor: Color(0xFF164B80),
    icon: Icons.settings_rounded,
  ),
  completed(
    label: 'Completed',
    backgroundColor: Color(0xFFD9F9E3),
    textColor: Color(0xFF006B30),
    icon: Icons.check_circle_rounded,
  ),
  declined(
    label: 'Declined',
    backgroundColor: Color(0xFFFFE2E2),
    textColor: Color(0xFFC53030),
    icon: Icons.cancel_rounded,
  );

  const ClientOrderStatus({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  /// Parses a raw status string from Firebase Realtime Database into [ClientOrderStatus].
  static ClientOrderStatus parse(String? rawStatus) {
    if (rawStatus == null) return ClientOrderStatus.pending;
    final normalized = rawStatus.trim().toLowerCase().replaceAll('-', '_');

    switch (normalized) {
      case 'pending':
        return ClientOrderStatus.pending;
      case 'confirmed':
      case 'accepted':
      case 'approved':
        return ClientOrderStatus.confirmed;
      case 'in_process':
      case 'in process':
      case 'inprocess':
      case 'processing':
      case 'shipped':
      case 'dispatched':
        return ClientOrderStatus.inProcess;
      case 'completed':
      case 'delivered':
      case 'done':
        return ClientOrderStatus.completed;
      case 'declined':
      case 'cancelled':
      case 'rejected':
        return ClientOrderStatus.declined;
      default:
        return ClientOrderStatus.pending;
    }
  }

  /// Checks if an order status matches this filter.
  bool matches(String? orderStatus) {
    if (this == ClientOrderStatus.all) return true;
    final parsed = ClientOrderStatus.parse(orderStatus);
    return parsed == this;
  }
}
