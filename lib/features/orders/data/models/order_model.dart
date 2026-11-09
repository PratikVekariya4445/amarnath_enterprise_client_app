import 'package:amarnath_enterprise_client_app/features/orders/domain/entities/order_entity.dart';

/// Data model representing an Order in Firebase Realtime Database.
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.orderId,
    required super.orderNumber,
    required super.clientId,
    required super.clientName,
    required super.clientMobile,
    required super.companyName,
    required super.clientCompanyName,
    required super.productId,
    required super.productName,
    super.productImage,
    super.productImageUrl,
    required super.unit,
    required super.price,
    super.size,
    required super.quantity,
    required super.amount,
    required super.totalAmount,
    super.status = 'pending',
    required super.createdAt,
    required super.updatedAt,
  });

  /// Factory constructor to safely deserialize from Firebase maps.
  factory OrderModel.fromJson(Map<dynamic, dynamic> json, [String keyId = '']) {
    final rawId = json['orderId'] ?? json['id'] ?? json['key'] ?? keyId;
    final resolvedId = (rawId is String && rawId.trim().isNotEmpty)
        ? rawId.trim()
        : 'ord_${DateTime.now().millisecondsSinceEpoch}';

    final orderNumber = json['orderNumber']
            ?.toString()
            .replaceAll('#', '')
            .trim() ??
        'ORD${(DateTime.now().millisecondsSinceEpoch % 90000) + 10000}';

    final clientId = json['clientId']?.toString().trim() ?? '';
    final clientName = json['clientName']?.toString().trim() ??
        json['name']?.toString().trim() ??
        '';
    final clientMobile = json['clientMobile']?.toString().trim() ??
        json['mobile']?.toString().trim() ??
        json['phone']?.toString().trim() ??
        '';
    final companyName = json['companyName']?.toString().trim() ??
        json['clientCompanyName']?.toString().trim() ??
        json['shopName']?.toString().trim() ??
        '';

    final productId = json['productId']?.toString().trim() ?? '';
    final productName = json['productName']?.toString().trim() ?? '';
    final productImage = json['productImage']?.toString().trim() ??
        json['productImageUrl']?.toString().trim() ??
        json['imageUrl']?.toString().trim();

    final unit = json['unit']?.toString().trim() ?? '';
    final rawPrice = json['price'];
    final double price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0;

    final size = json['size']?.toString().trim();
    final rawQty = json['quantity'] ?? json['qty'] ?? 1;
    final int quantity =
        rawQty is int ? rawQty : int.tryParse(rawQty.toString()) ?? 1;

    final totalAmount = json['totalAmount']?.toString().trim() ??
        json['amount']?.toString().trim() ??
        (price * quantity).toStringAsFixed(0);

    final status = json['status']?.toString().trim() ?? 'pending';
    final createdAt = json['createdAt']?.toString().trim() ??
        DateTime.now().toIso8601String();
    final updatedAt = json['updatedAt']?.toString().trim() ?? createdAt;

    return OrderModel(
      id: resolvedId,
      orderId: resolvedId,
      orderNumber: orderNumber,
      clientId: clientId,
      clientName: clientName,
      clientMobile: clientMobile,
      companyName: companyName,
      clientCompanyName: companyName,
      productId: productId,
      productName: productName,
      productImage: productImage,
      productImageUrl: productImage,
      unit: unit,
      price: price,
      size: size,
      quantity: quantity,
      amount: totalAmount,
      totalAmount: totalAmount,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Serializes to JSON map for saving into `amarntath_enterprise/orders/{orderId}`.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'clientId': clientId,
      'clientName': clientName,
      'clientMobile': clientMobile,
      'companyName': companyName,
      'clientCompanyName': clientCompanyName,
      'productId': productId,
      'productName': productName,
      if (productImage != null && productImage!.isNotEmpty)
        'productImage': productImage,
      if (productImageUrl != null && productImageUrl!.isNotEmpty)
        'productImageUrl': productImageUrl,
      'unit': unit,
      'price': price,
      if (size != null && size!.isNotEmpty) 'size': size,
      'quantity': quantity,
      'amount': amount,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      orderId: entity.orderId,
      orderNumber: entity.orderNumber,
      clientId: entity.clientId,
      clientName: entity.clientName,
      clientMobile: entity.clientMobile,
      companyName: entity.companyName,
      clientCompanyName: entity.clientCompanyName,
      productId: entity.productId,
      productName: entity.productName,
      productImage: entity.productImage,
      productImageUrl: entity.productImageUrl,
      unit: entity.unit,
      price: entity.price,
      size: entity.size,
      quantity: entity.quantity,
      amount: entity.amount,
      totalAmount: entity.totalAmount,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
