class Product {
  final int? id;
  final String name;
  final String category;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double stockQuantity;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockQuantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['product_id'],
      name: map['name'],
      category: map['category'],
      unit: map['unit'],
      purchasePrice: map['purchase_price'] ?? 0,
      sellingPrice: map['selling_price'] ?? 0,
      stockQuantity: map['stock_quantity'] ?? 0,
    );
  }
}
