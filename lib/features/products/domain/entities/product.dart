import 'package:equatable/equatable.dart';

/// Domain entity representing a Product in the Amarnath Enterprise catalog.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.unit,
    this.packSize,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.sizes = const [],
    this.images = const [],
    this.brand,
    this.type,
    this.weight,
    this.grade,
    this.specifications = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier (e.g. Firebase key or UUID).
  final String id;

  /// Business product name (e.g. `Steel Rod`, `Square Pipe`).
  final String name;

  /// Business product item number or code (e.g. `1001`, `PRD-1002`).
  final String code;

  /// Base price in INR.
  final double price;

  /// Unit of measurement (e.g. `Pcs`, `Kg`, `Mtr`, `Bundle`).
  final String unit;

  /// Optional pack size count.
  final int? packSize;

  /// Detailed product description.
  final String? description;

  /// Download URL or asset path for product image.
  final String? imageUrl;

  /// Active status in the catalog.
  final bool isActive;

  /// Available sizes (e.g. `['6 mm', '8 mm', '10 mm']` or `['20 x 20', '25 x 25']`).
  final List<String> sizes;

  /// Optional list of product images for carousel.
  final List<String> images;

  /// Brand name (e.g. `UltraTech`, `Tata Tiscon`).
  final String? brand;

  /// Product type (e.g. `OPC (Ordinary Portland Cement)`, `TMT Rebars`).
  final String? type;

  /// Product weight or size package (e.g. `50 kg`, `1 bundle`).
  final String? weight;

  /// Product grade (e.g. `53 Grade`, `Fe 550D`).
  final String? grade;

  /// Custom specifications map (e.g. `{ 'Finish': 'Galvanized' }`).
  final Map<String, String> specifications;

  /// ISO 8601 creation timestamp.
  final String createdAt;

  /// ISO 8601 update timestamp.
  final String updatedAt;

  /// Returns all available images, falling back to [imageUrl] if [images] is empty.
  List<String> get allImages {
    if (images.isNotEmpty) {
      return images.where((img) => img.trim().isNotEmpty).toList();
    }
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return [imageUrl!.trim()];
    }
    return const [];
  }

  /// User-facing formatted string of available sizes.
  String get displaySizes {
    if (sizes.isNotEmpty) {
      return sizes.join(', ');
    }
    if (unit.isNotEmpty) {
      return unit;
    }
    return '';
  }

  /// Determines whether product was recently added (within the last 30 days).
  bool get isNew {
    try {
      final created = DateTime.tryParse(createdAt);
      if (created == null) return true;
      return DateTime.now().difference(created).inDays <= 30;
    } catch (_) {
      return true;
    }
  }

  Product copyWith({
    String? id,
    String? name,
    String? code,
    double? price,
    String? unit,
    int? packSize,
    String? description,
    String? imageUrl,
    bool? isActive,
    List<String>? sizes,
    List<String>? images,
    String? brand,
    String? type,
    String? weight,
    String? grade,
    Map<String, String>? specifications,
    String? createdAt,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      packSize: packSize ?? this.packSize,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      sizes: sizes ?? this.sizes,
      images: images ?? this.images,
      brand: brand ?? this.brand,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      grade: grade ?? this.grade,
      specifications: specifications ?? this.specifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        price,
        unit,
        packSize,
        description,
        imageUrl,
        isActive,
        sizes,
        images,
        brand,
        type,
        weight,
        grade,
        specifications,
        createdAt,
        updatedAt,
      ];
}
