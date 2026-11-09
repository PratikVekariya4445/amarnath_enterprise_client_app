import 'package:equatable/equatable.dart';
import 'package:amarnath_enterprise_client_app/core/utils/currency_utils.dart';
import 'package:amarnath_enterprise_client_app/core/utils/date_formatter.dart';
import 'package:amarnath_enterprise_client_app/features/orders/presentation/models/client_order_status.dart';

/// Domain entity representing an Order placed by a Client.
class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.clientId,
    required this.clientName,
    required this.clientMobile,
    required this.companyName,
    required this.clientCompanyName,
    required this.productId,
    required this.productName,
    this.productImage,
    this.productImageUrl,
    required this.unit,
    required this.price,
    this.size,
    required this.quantity,
    required this.amount,
    required this.totalAmount,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique order key / ID.
  final String id;

  /// Order identifier (`orderId`).
  final String orderId;

  /// Display order number / code (e.g. `ORD10023`).
  final String orderNumber;

  /// Authenticated client UID.
  final String clientId;

  /// Client full name.
  final String clientName;

  /// Client contact mobile number.
  final String clientMobile;

  /// Client company or shop name.
  final String companyName;

  /// Alias for company name matching Owner app convention.
  final String clientCompanyName;

  /// Associated Product ID.
  final String productId;

  /// Product name (e.g. `UltraTech Cement (53 Grade)`).
  final String productName;

  /// Product image URL.
  final String? productImage;

  /// Alias for product image URL matching Owner app convention.
  final String? productImageUrl;

  /// Product unit (e.g. `Bag`, `Kg`, `Piece`).
  final String unit;

  /// Base price per unit.
  final double price;

  /// Optional size or variant (e.g. `50 kg`).
  final String? size;

  /// Quantity ordered.
  final int quantity;

  /// Order total amount string (e.g. `4200`).
  final String amount;

  /// Total amount string (`totalAmount`).
  final String totalAmount;

  /// Order status (`pending`, `accepted`, `declined`, `completed`).
  final String status;

  /// ISO 8601 creation timestamp.
  final String createdAt;

  /// ISO 8601 update timestamp.
  final String updatedAt;

  // ==========================================
  // Display & UI Convenience Helpers
  // ==========================================

  /// Clean display order number: `Order #ORD001245`.
  String get displayOrderNumber {
    final clean = orderNumber.replaceAll('#', '').trim();
    return 'Order #$clean';
  }

  /// Formatted date and time string: `08 Nov 2026, 02:15 PM`.
  String get formattedDateTime {
    return DateFormatter.formatOrderDateTime(createdAt);
  }

  /// Normalized [ClientOrderStatus].
  ClientOrderStatus get clientStatus => ClientOrderStatus.parse(status);

  /// Returns unit/pack size specification (e.g. `50 kg Bag`).
  String get displaySpecification {
    final cleanSize = size?.trim() ?? '';
    final cleanUnit = unit.trim();
    if (cleanSize.isEmpty) {
      return cleanUnit;
    }
    if (cleanUnit.isEmpty || cleanSize.toLowerCase().contains(cleanUnit.toLowerCase())) {
      return cleanSize;
    }
    return '$cleanSize $cleanUnit';
  }

  /// Returns unit pluralized if appropriate (e.g. `Bags`).
  String get displayUnitWithPlural {
    final u = unit.trim();
    if (u.isEmpty) return '';
    if (quantity > 1) {
      final lower = u.toLowerCase();
      if (lower == 'bag') return 'Bags';
      if (lower == 'packet' || lower == 'pkt') return 'Packets';
      if (lower == 'box') return 'Boxes';
      if (lower == 'piece' || lower == 'pc') return 'Pieces';
      if (lower == 'bundle') return 'Bundles';
    }
    return u;
  }

  /// Returns single unit string for unit price: `₹420 / Bag`.
  String get displayUnitPrice {
    final cleanPrice = price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);
    final u = unit.trim().isNotEmpty ? unit.trim() : 'Unit';
    return '₹$cleanPrice / $u';
  }

  /// Formats quantity and unit price line: `Qty: 10 Bags  |  ₹420 / Bag`.
  String get displayQuantityAndPrice {
    final qtyUnit = displayUnitWithPlural;
    final qtyStr = qtyUnit.isNotEmpty ? 'Qty: $quantity $qtyUnit' : 'Qty: $quantity';
    return '$qtyStr  |  $displayUnitPrice';
  }

  /// Numeric total calculated or parsed.
  double get numericTotal {
    final parsed = CurrencyUtils.parseAmount(totalAmount.isNotEmpty ? totalAmount : amount);
    if (parsed > 0) return parsed;
    return price * quantity;
  }

  /// Indian formatted total amount: `₹ 4,200`.
  String get formattedTotalAmount {
    return CurrencyUtils.formatWithRupee(numericTotal);
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        orderNumber,
        clientId,
        clientName,
        clientMobile,
        companyName,
        productId,
        productName,
        quantity,
        totalAmount,
        status,
        createdAt,
        updatedAt,
      ];
}
