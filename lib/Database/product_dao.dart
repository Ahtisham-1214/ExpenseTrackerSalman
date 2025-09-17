import 'package:sqflite/sqflite.dart';
import '../Model/product.dart';

class ProductDao {
  final Database db;
  ProductDao(this.db);

  Future<int> insertProduct(Product product) async {
    return await db.insert('Products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getAllProducts() async {
    final result = await db.query('Products', orderBy: 'name ASC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<String>> getDistinctCategories() async {
    final result = await db.rawQuery("SELECT DISTINCT category FROM Products");
    return result.map((row) => row['category'] as String).toList();
  }

  Future<int> getProductsCount() async {
    final result = await db.rawQuery("SELECT COUNT(*) FROM Products");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Product?> getProductById(int id) async {
    final result = await db.query(
      'Products',
      where: 'product_id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    return await db.update(
      'Products',
      product.toMap(),
      where: 'product_id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    return await db.delete(
      'Products',
      where: 'product_id = ?',
      whereArgs: [id],
    );
  }
}
