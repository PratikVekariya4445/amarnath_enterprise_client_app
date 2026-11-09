import 'package:amarnath_enterprise_client_app/features/products/domain/entities/product.dart';

abstract class ProductRepository {
  /// Retrieves all active products from the catalog.
  Future<List<Product>> getProducts();

  /// Retrieves the latest products ordered newest first (by [Product.createdAt]).
  Future<List<Product>> getRecentlyAddedProducts({int limit = 10});

  /// Searches products matching name or item number.
  Future<List<Product>> searchProducts(String query);
}
