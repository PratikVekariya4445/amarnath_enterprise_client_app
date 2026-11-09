import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';

/// Data model representing a Product in Firebase Realtime Database.
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.code,
    required super.price,
    required super.unit,
    super.packSize,
    super.description,
    super.imageUrl,
    super.isActive = true,
    super.sizes = const [],
    super.images = const [],
    super.brand,
    super.type,
    super.weight,
    super.grade,
    super.specifications = const {},
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProductModel.fromJson(Map<dynamic, dynamic> json, [String id = '']) {
    // 1. Safe ID extraction (fallback to child key)
    final resolvedId = (json['id'] as String?)?.trim().isNotEmpty == true
        ? json['id'].toString().trim()
        : (id.trim().isNotEmpty
            ? id.trim()
            : 'prod_${DateTime.now().millisecondsSinceEpoch}');

    // 2. Safe Name
    final name = json['name']?.toString().trim() ??
        json['productName']?.toString().trim() ??
        '';

    // 3. Safe Code / Item No
    final code = json['code']?.toString().trim() ??
        json['itemNo']?.toString().trim() ??
        json['itemNumber']?.toString().trim() ??
        json['productCode']?.toString().trim() ??
        '';

    // 4. Safe Price conversion (handles num, int, double, String)
    double parsedPrice = 0.0;
    final rawPrice = json['price'] ?? json['productPrice'];
    if (rawPrice is num) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice is String) {
      parsedPrice =
          double.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }

    // 5. Safe Unit
    final unit =
        json['unit']?.toString().trim() ?? json['unitType']?.toString().trim() ?? '';

    // 6. Safe Pack Size
    int? parsedPackSize;
    final rawPackSize =
        json['packSize'] ?? json['pack_size'] ?? json['packageSize'];
    if (rawPackSize is num) {
      parsedPackSize = rawPackSize.toInt();
    } else if (rawPackSize is String) {
      parsedPackSize =
          int.tryParse(rawPackSize.replaceAll(RegExp(r'[^0-9]'), ''));
    }

    // 7. Safe Description
    final description =
        json['description']?.toString().trim() ?? json['desc']?.toString().trim();

    // 8. Safe Image URL (handles imageUrl, image, photoUrl, image_url, and List<images>)
    String? resolvedImageUrl;
    final rawImg = json['imageUrl'] ??
        json['image'] ??
        json['photoUrl'] ??
        json['image_url'];
    if (rawImg is String && rawImg.trim().isNotEmpty) {
      resolvedImageUrl = rawImg.trim();
    } else if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      resolvedImageUrl = (json['images'] as List).first?.toString().trim();
    }

    // 9. Safe isActive
    bool active = true;
    final rawActive = json['isActive'] ?? json['active'] ?? json['is_active'];
    if (rawActive is bool) {
      active = rawActive;
    } else if (rawActive is num) {
      active = rawActive != 0;
    } else if (rawActive is String) {
      active = rawActive.toLowerCase() == 'true' || rawActive == '1';
    }

    // 10. Safe Sizes
    List<String> parsedSizes = [];
    final rawSizes = json['sizes'] ?? json['availableSizes'] ?? json['sizeList'];
    if (rawSizes is List) {
      parsedSizes = rawSizes
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawSizes is String && rawSizes.trim().isNotEmpty) {
      parsedSizes = rawSizes
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // 11. Safe Images (List of images)
    List<String> parsedImages = [];
    final rawImages = json['images'] ?? json['imageUrls'] ?? json['photos'];
    if (rawImages is List) {
      parsedImages = rawImages
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawImages is String && rawImages.trim().isNotEmpty) {
      parsedImages = rawImages
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (parsedImages.isEmpty && resolvedImageUrl != null && resolvedImageUrl.isNotEmpty) {
      parsedImages = [resolvedImageUrl];
    }

    // 12. Safe Brand
    final brand = json['brand']?.toString().trim() ??
        json['brandName']?.toString().trim() ??
        json['company']?.toString().trim();

    // 13. Safe Type
    final type = json['type']?.toString().trim() ??
        json['productType']?.toString().trim() ??
        json['category']?.toString().trim();

    // 14. Safe Weight
    final weight = json['weight']?.toString().trim() ??
        json['netWeight']?.toString().trim();

    // 15. Safe Grade
    final grade = json['grade']?.toString().trim() ??
        json['qualityGrade']?.toString().trim();

    // 16. Safe Specifications Map
    final Map<String, String> parsedSpecs = {};
    final rawSpecs = json['specifications'] ?? json['specs'];
    if (rawSpecs is Map) {
      rawSpecs.forEach((k, v) {
        if (k != null && v != null) {
          final kStr = k.toString().trim();
          final vStr = v.toString().trim();
          if (kStr.isNotEmpty && vStr.isNotEmpty) {
            parsedSpecs[kStr] = vStr;
          }
        }
      });
    }

    // 17. Safe Timestamps (handles epoch num or ISO String)
    String safeIsoString(dynamic raw) {
      if (raw == null) return DateTime.now().toIso8601String();
      if (raw is num) {
        return DateTime.fromMillisecondsSinceEpoch(raw.toInt())
            .toIso8601String();
      }
      final str = raw.toString().trim();
      final parsed = DateTime.tryParse(str);
      if (parsed != null) return parsed.toIso8601String();
      final numParsed = int.tryParse(str);
      if (numParsed != null) {
        return DateTime.fromMillisecondsSinceEpoch(numParsed).toIso8601String();
      }
      return str;
    }

    return ProductModel(
      id: resolvedId,
      name: name,
      code: code,
      price: parsedPrice,
      unit: unit,
      packSize: parsedPackSize,
      description: description,
      imageUrl: resolvedImageUrl,
      isActive: active,
      sizes: parsedSizes,
      images: parsedImages,
      brand: brand,
      type: type,
      weight: weight,
      grade: grade,
      specifications: parsedSpecs,
      createdAt: safeIsoString(json['createdAt']),
      updatedAt: safeIsoString(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'price': price,
      'unit': unit,
      if (packSize != null) 'packSize': packSize,
      'description': description ?? '',
      'imageUrl': imageUrl ?? '',
      'isActive': isActive,
      'sizes': sizes,
      if (images.isNotEmpty) 'images': images,
      if (brand != null) 'brand': brand,
      if (type != null) 'type': type,
      if (weight != null) 'weight': weight,
      if (grade != null) 'grade': grade,
      if (specifications.isNotEmpty) 'specifications': specifications,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      code: product.code,
      price: product.price,
      unit: product.unit,
      packSize: product.packSize,
      description: product.description,
      imageUrl: product.imageUrl,
      isActive: product.isActive,
      sizes: product.sizes,
      images: product.images,
      brand: product.brand,
      type: product.type,
      weight: product.weight,
      grade: product.grade,
      specifications: product.specifications,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }
}
