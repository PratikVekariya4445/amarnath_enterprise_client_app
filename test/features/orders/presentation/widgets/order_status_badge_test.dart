import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/core/utils/responsive_utils.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/models/client_order_status.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/widgets/order_status_badge.dart';

Widget _buildTestableBadge(ClientOrderStatus status) {
  return Sizer(
    builder: (context, orientation, deviceType) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: OrderStatusBadge(status: status),
          ),
        ),
      );
    },
  );
}

void main() {
  group('OrderStatusBadge Tests', () {
    testWidgets('renders Pending status badge with correct colors and icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestableBadge(ClientOrderStatus.pending));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFFFF1BE));
    });

    testWidgets('renders Confirmed status badge with correct colors and icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestableBadge(ClientOrderStatus.confirmed));
      await tester.pumpAndSettle();

      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFD9F9E3));
    });

    testWidgets('renders In Process status badge with correct colors and icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestableBadge(ClientOrderStatus.inProcess));
      await tester.pumpAndSettle();

      expect(find.text('In Process'), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFD9EEFF));
    });

    testWidgets('renders Completed status badge with correct colors and icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestableBadge(ClientOrderStatus.completed));
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFD9F9E3));
    });
  });
}
