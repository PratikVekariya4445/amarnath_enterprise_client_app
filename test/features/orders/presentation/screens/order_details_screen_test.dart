import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/entities/order_entity.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/screens/order_details_screen.dart';

Widget _buildTestableOrderDetailsScreen(OrderEntity order) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        home: OrderDetailsScreen(
          orderId: order.orderId,
          initialOrder: order,
        ),
      );
    },
  );
}

void main() {
  group('OrderDetailsScreen Widget Tests', () {
    const testOrder = OrderEntity(
      id: 'ord_1',
      orderId: 'ord_1',
      orderNumber: 'ORD001245',
      clientId: 'c1',
      clientName: 'Ramesh Patel',
      clientMobile: '9876543210',
      companyName: 'Patel Hardware',
      clientCompanyName: 'Patel Hardware',
      productId: 'p1',
      productName: 'UltraTech Cement (53 Grade)',
      unit: 'Bag',
      price: 420.0,
      size: '50 kg',
      quantity: 10,
      amount: '4200',
      totalAmount: '4200',
      status: 'pending',
      createdAt: '2026-11-08T14:15:00.000Z',
      updatedAt: '2026-11-08T14:15:00.000Z',
    );

    testWidgets('renders all cards with complete order details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestableOrderDetailsScreen(testOrder));
      await tester.pumpAndSettle();

      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('Order #ORD001245'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      expect(find.text('Product Details'), findsOneWidget);
      expect(find.text('UltraTech Cement (53 Grade)'), findsOneWidget);

      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Total Amount'), findsOneWidget);
      expect(find.text('₹ 4,200'), findsNWidgets(2)); // Item price & Total Amount

      expect(find.text('Client Information'), findsOneWidget);
      expect(find.text('Ramesh Patel'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('Patel Hardware'), findsOneWidget);
    });
  });
}
