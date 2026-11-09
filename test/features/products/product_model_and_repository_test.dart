import 'package:flutter_test/flutter_test.dart';
import 'package:amarnath_enterprise_client_app/features/products/data/datasources/product_remote_datasource.dart';
import 'package:amarnath_enterprise_client_app/features/products/data/models/product_model.dart';
import 'package:amarnath_enterprise_client_app/features/products/data/repositories/product_repository_impl.dart';

class MockProductRemoteDataSource implements ProductRemoteDataSource {
  List<ProductModel> mockProducts = [];

  @override
  Future<List<ProductModel>> getProducts() async => mockProducts;
}

void main() {
  group('ProductModel Unit Tests', () {
    test('parses json correctly with sizes list and calculates displaySizes', () {
      final json = {
        'id': 'prod_1',
        'name': 'Steel Rod',
        'code': '1001',
        'price': 250.0,
        'unit': 'Kg',
        'sizes': ['6 mm', '8 mm', '10 mm'],
        'isActive': true,
        'createdAt': '2026-11-01T10:00:00.000Z',
        'updatedAt': '2026-11-01T10:00:00.000Z',
      };

      final product = ProductModel.fromJson(json, 'prod_1');

      expect(product.id, 'prod_1');
      expect(product.name, 'Steel Rod');
      expect(product.code, '1001');
      expect(product.price, 250.0);
      expect(product.unit, 'Kg');
      expect(product.sizes, ['6 mm', '8 mm', '10 mm']);
      expect(product.displaySizes, '6 mm, 8 mm, 10 mm');
      expect(product.isNew, isTrue);
    });

    test('parses comma-separated string for sizes and handles price strings', () {
      final json = {
        'name': 'Square Pipe',
        'itemNumber': '1002',
        'price': '₹ 450.50',
        'unit': 'Pcs',
        'sizes': '20 x 20, 25 x 25, 40 x 40',
        'isActive': 'true',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      final product = ProductModel.fromJson(json, 'prod_2');

      expect(product.name, 'Square Pipe');
      expect(product.code, '1002');
      expect(product.price, 450.50);
      expect(product.sizes, ['20 x 20', '25 x 25', '40 x 40']);
      expect(product.displaySizes, '20 x 20, 25 x 25, 40 x 40');
      expect(product.isActive, isTrue);
    });

    test('falls back to unit when sizes are empty', () {
      final json = {
        'name': 'Hex Bolt',
        'code': '1003',
        'price': 15,
        'unit': '10 Pcs/Pack',
        'isActive': true,
      };

      final product = ProductModel.fromJson(json, 'prod_3');
      expect(product.sizes, isEmpty);
      expect(product.displaySizes, '10 Pcs/Pack');
    });
  });

  group('ProductRepositoryImpl Unit Tests', () {
    late MockProductRemoteDataSource mockDataSource;
    late ProductRepositoryImpl repository;

    setUp(() {
      mockDataSource = MockProductRemoteDataSource();
      repository = ProductRepositoryImpl(dataSource: mockDataSource);
    });

    test('getRecentlyAddedProducts sorts by createdAt descending', () async {
      mockDataSource.mockProducts = [
        ProductModel.fromJson({
          'id': 'old',
          'name': 'Old Product',
          'code': '001',
          'price': 100,
          'unit': 'Pcs',
          'createdAt': '2026-10-01T00:00:00.000Z',
          'updatedAt': '2026-10-01T00:00:00.000Z',
        }),
        ProductModel.fromJson({
          'id': 'new',
          'name': 'New Product',
          'code': '002',
          'price': 200,
          'unit': 'Pcs',
          'createdAt': '2026-11-03T00:00:00.000Z',
          'updatedAt': '2026-11-03T00:00:00.000Z',
        }),
        ProductModel.fromJson({
          'id': 'mid',
          'name': 'Mid Product',
          'code': '003',
          'price': 150,
          'unit': 'Pcs',
          'createdAt': '2026-10-15T00:00:00.000Z',
          'updatedAt': '2026-10-15T00:00:00.000Z',
        }),
      ];

      final recent = await repository.getRecentlyAddedProducts();

      expect(recent.length, 3);
      expect(recent[0].id, 'new');
      expect(recent[1].id, 'mid');
      expect(recent[2].id, 'old');
    });

    test('searchProducts filters by name or code', () async {
      mockDataSource.mockProducts = [
        ProductModel.fromJson({
          'id': 'p1',
          'name': 'Steel Rod',
          'code': '1001',
          'price': 100,
          'unit': 'Kg',
        }),
        ProductModel.fromJson({
          'id': 'p2',
          'name': 'Square Pipe',
          'code': '1002',
          'price': 200,
          'unit': 'Pcs',
        }),
      ];

      final resultByName = await repository.searchProducts('Steel');
      expect(resultByName.length, 1);
      expect(resultByName.first.id, 'p1');

      final resultCode = await repository.searchProducts('1002');
      expect(resultCode.length, 1);
      expect(resultCode.first.id, 'p2');
    });
  });
}
