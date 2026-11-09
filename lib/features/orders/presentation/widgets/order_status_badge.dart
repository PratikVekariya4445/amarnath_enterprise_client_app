import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/models/client_order_status.dart';

/// Pill-shaped status badge matching reference design specifications.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    super.key,
    required this.status,
  });

  final ClientOrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.dp,
        vertical: 4.5.dp,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20.dp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            status.icon,
            size: 14.5.dp,
            color: status.textColor,
          ),
          SizedBox(width: 4.5.dp),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: status.textColor,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
