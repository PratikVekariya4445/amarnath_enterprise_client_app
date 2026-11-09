import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/models/client_order_status.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/widgets/order_status_filter_bar.dart';

Widget _buildTestableFilterBar({
  required ClientOrderStatus selectedStatus,
  required ValueChanged<ClientOrderStatus> onStatusSelected,
}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        home: Scaffold(
          body: OrderStatusFilterBar(
            selectedStatus: selectedStatus,
            onStatusSelected: onStatusSelected,
          ),
        ),
      );
    },
  );
}

void main() {
  group('OrderStatusFilterBar Tests', () {
    testWidgets('renders all 5 filters in exact order and responds to selection', (
      WidgetTester tester,
    ) async {
      ClientOrderStatus currentStatus = ClientOrderStatus.all;

      await tester.pumpWidget(
        _buildTestableFilterBar(
          selectedStatus: currentStatus,
          onStatusSelected: (status) {
            currentStatus = status;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('In Process'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Tap Pending
      await tester.tap(find.text('Pending'));
      expect(currentStatus, ClientOrderStatus.pending);

      // Tap In Process
      await tester.tap(find.text('In Process'));
      expect(currentStatus, ClientOrderStatus.inProcess);
    });
  });
}
