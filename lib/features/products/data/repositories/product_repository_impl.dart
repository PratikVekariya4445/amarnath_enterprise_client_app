import 'package:amarnath_enterprise_client_app/features/products/data/datasources/product_remote_datasource.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';
import 'package:amarnath_enterprise_client_app/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({ProductRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? ProductRemoteDataSourceImpl();

  final ProductRemoteDataSource _dataSource;

  @override
  Future<List<Product>> getProducts() async {
    final products = await _dataSource.getProducts();
    // Filter active items
    return products.where((p) => p.isActive).toList();
  }

  @override
  Future<List<Product>> getRecentlyAddedProducts({int limit = 10}) async {
    final products = await getProducts();

    // Sort by createdAt descending (newest first)
    products.sort((a, b) {
      final dateA = DateTime.tryParse(a.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b.createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    if (products.length > limit) {
      return products.sublist(0, limit);
    }
    return products;
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return getProducts();
    }

    final products = await getProducts();
    return products.where((p) {
      final nameMatches = p.name.toLowerCase().contains(cleanQuery);
      final codeMatches = p.code.toLowerCase().contains(cleanQuery);
      final descMatches =
          p.description?.toLowerCase().contains(cleanQuery) ?? false;
      return nameMatches || codeMatches || descMatches;
    }).toList();
  }
}
