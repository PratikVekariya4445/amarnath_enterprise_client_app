import 'package:flutter/material.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/models/client_order_status.dart';

/// Horizontally scrollable status filter tabs matching the reference design.
///
/// Order of tabs:
/// 1. All
/// 2. Pending
/// 3. Confirmed
/// 4. In Process
/// 5. Completed
class OrderStatusFilterBar extends StatelessWidget {
  const OrderStatusFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  final ClientOrderStatus selectedStatus;
  final ValueChanged<ClientOrderStatus> onStatusSelected;

  static const List<ClientOrderStatus> _filters = [
    ClientOrderStatus.all,
    ClientOrderStatus.pending,
    ClientOrderStatus.confirmed,
    ClientOrderStatus.inProcess,
    ClientOrderStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 12.dp),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.dp),
        child: Row(
          children: _filters.map((status) {
            final isSelected = selectedStatus == status;
            return Padding(
              padding: EdgeInsets.only(right: 10.dp),
              child: InkWell(
                onTap: () => onStatusSelected(status),
                borderRadius: BorderRadius.circular(20.dp),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.dp,
                    vertical: 8.5.dp,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00864D)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20.dp),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: const Color(0xFFD9DDE0),
                            width: 1.dp,
                          ),
                  ),
                  child: Center(
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF111111),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
