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
}
