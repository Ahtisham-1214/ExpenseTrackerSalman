import 'package:flutter/material.dart';
import '/Database/app_database.dart';
import '/Database/product_dao.dart';
import '/Model/product.dart';
import 'package:intl/intl.dart';

class InventoryList extends StatefulWidget {
  const InventoryList({super.key});

  @override
  InventoryListState createState() => InventoryListState(); // 👈 make state public
}

class InventoryListState extends State<InventoryList> {
  List<Product> _products = [];
  int? _expandedIndex; // Track expanded card

  final _numberFormat = NumberFormat("#,##0.00", "en_PK");

  String formatPrice(double value) {
    return "${_numberFormat.format(value)} Rs";
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final db = await AppDatabase.instance.database;
    final dao = ProductDao(db);
    final prods = await dao.getAllProducts();
    setState(() => _products = prods);
  }

  /// 👇 Public method to refresh list from outside
  Future<void> refresh() async {
    await _fetchProducts();
  }

  Future<void> _editProduct(Product product) async {
    final nameController = TextEditingController(text: product.name);
    final categoryController = TextEditingController(text: product.category);
    final unitController = TextEditingController(text: product.unit);
    final purchasePriceController = TextEditingController(text: product.purchasePrice.toString());
    final sellingPriceController = TextEditingController(text: product.sellingPrice.toString());
    final stockController = TextEditingController(text: product.stockQuantity.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: purchasePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Purchase Price'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sellingPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Selling Price'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final updatedProduct = Product(
          id: product.id,
          name: nameController.text.trim(),
          category: categoryController.text.trim(),
          unit: unitController.text.trim(),
          purchasePrice: double.tryParse(purchasePriceController.text) ?? 0.0,
          sellingPrice: double.tryParse(sellingPriceController.text) ?? 0.0,
          stockQuantity: double.tryParse(stockController.text) ?? 0.0,
        );

        final db = await AppDatabase.instance.database;
        final productDao = ProductDao(db);
        await productDao.updateProduct(updatedProduct);

        await _fetchProducts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating product: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final db = await AppDatabase.instance.database;
        final productDao = ProductDao(db);
        await productDao.deleteProduct(product.id!);

        await _fetchProducts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting product: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) {
      return const Center(child: Text("No products available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final bool isExpanded = _expandedIndex == index;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState:
                  isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              firstChild: _buildCompactCard(context, product),
              secondChild: _buildDetailCard(context, product),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactCard(BuildContext context, Product product) {
    final bool isLowStock =
        product.stockQuantity > 0 && product.stockQuantity < 10;
    final bool isOutOfStock = product.stockQuantity == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isOutOfStock
                          ? Colors.red.shade100
                          : isLowStock
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isOutOfStock
                            ? Colors.red.shade300
                            : isLowStock
                            ? Colors.orange.shade300
                            : Colors.green.shade300,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  "${product.stockQuantity} stock",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isOutOfStock
                            ? Colors.red.shade700
                            : isLowStock
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactDetailItem(
                context,
                icon: Icons.category_outlined,
                label: product.category,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactDetailItem(
                context,
                icon: Icons.sell_outlined,
                label: formatPrice(product.sellingPrice),
                isLabelBold: true,
                labelColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isLabelBold = false,
    Color? labelColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: isLabelBold ? FontWeight.bold : FontWeight.normal,
            color: labelColor ?? Colors.grey[700],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDetailCard(BuildContext context, Product product) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  product.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            Icons.category_outlined,
            "Category",
            product.category,
          ),
          _buildDetailRow(
            context,
            Icons.straighten_outlined,
            "Unit",
            product.unit,
          ),
          _buildDetailRow(
            context,
            Icons.shopping_cart_checkout_outlined,
            "Purchase Price",
            formatPrice(product.purchasePrice),
          ),
          _buildDetailRow(
            context,
            Icons.sell_outlined,
            "Selling Price",
            formatPrice(product.sellingPrice),
          ),
          _buildDetailRow(
            context,
            product.stockQuantity > 0
                ? Icons.store_mall_directory_outlined
                : Icons.warning_amber_rounded,
            "Stock Quantity",
            product.stockQuantity.toString(),
            valueColor:
                product.stockQuantity > 0
                    ? (product.stockQuantity < 10
                        ? Colors.orange.shade700
                        : Colors.green.shade700)
                    : Colors.red.shade700,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _editProduct(product),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deleteProduct(product),
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
