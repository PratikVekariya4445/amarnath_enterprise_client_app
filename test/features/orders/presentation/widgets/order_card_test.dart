import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/orders/domain/entities/order_entity.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/widgets/order_card.dart';

Widget _buildTestableCard({
  required OrderEntity order,
  VoidCallback? onTap,
}) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        home: Scaffold(
          body: OrderCard(
            order: order,
            onTap: onTap,
          ),
        ),
      );
    },
  );
}

void main() {
  group('OrderCard Widget Tests', () {
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

    testWidgets('renders all visual elements matching sample Card 1', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        _buildTestableCard(
          order: testOrder,
          onTap: () {
            tapped = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order #ORD001245'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('UltraTech Cement (53 Grade)'), findsOneWidget);
      expect(find.text('50 kg Bag'), findsOneWidget);
      expect(find.text('Qty: 10 Bags  |  ₹420 / Bag'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('₹ 4,200'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.byType(OrderCard));
      expect(tapped, isTrue);
    });
  });
}
