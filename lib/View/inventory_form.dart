import 'package:flutter/material.dart';
import '/Database/app_database.dart';
import '/Database/product_dao.dart';
import '/Model/product.dart';

class InventoryForm extends StatefulWidget {
  final VoidCallback onProductAdded; // callback to refresh list

  const InventoryForm({super.key, required this.onProductAdded});

  @override
  State<InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<InventoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final db = await AppDatabase.instance.database;
    final dao = ProductDao(db);
    final cats = await dao.getDistinctCategories();
    setState(() => _categories = cats);
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final db = await AppDatabase.instance.database;
      final dao = ProductDao(db);

      final product = Product(
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        unit: _unitController.text.trim(),
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0,
        stockQuantity: double.tryParse(_stockController.text) ?? 0,
      );

      await dao.insertProduct(product);

      // Clear form
      _formKey.currentState!.reset();
      _nameController.clear();
      _unitController.clear();
      _purchasePriceController.clear();
      _sellingPriceController.clear();
      _stockController.clear();
      setState(() => _selectedCategory = null);

      // Refresh categories (if new added)
      await _fetchCategories();

      // Refresh product list
      widget.onProductAdded();

      // Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Product added successfully")),
      );

      // Refocus to name field for faster entry
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }


  Future<String?> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter category name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newCat = controller.text.trim();
              if (newCat.isNotEmpty && !_categories.contains(newCat)) {
                Navigator.pop(ctx, newCat);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⚠️ Category already exists")),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Product Name",
                prefixIcon: Icon(Icons.inventory),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? "Enter product name" : null,
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              ))
                  .toList()
                ..add(
                  const DropdownMenuItem(
                    value: "__add_new__",
                    child: Text("+ Add New Category"),
                  ),
                ),
              onChanged: (value) async {
                if (value == "__add_new__") {
                  final newCat = await _showAddCategoryDialog();
                  if (newCat != null &&
                      newCat.trim().isNotEmpty &&
                      !_categories.contains(newCat)) {
                    setState(() {
                      _categories.add(newCat);
                      _selectedCategory = newCat;
                    });
                  }
                } else {
                  setState(() => _selectedCategory = value);
                }
              },
              decoration: const InputDecoration(
                labelText: "Category",
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null ? "Select a category" : null,
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: "Unit (e.g. kg, pcs)",
                prefixIcon: Icon(Icons.straighten),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _purchasePriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Purchase Price",
                prefixIcon: Icon(Icons.shopping_cart),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _sellingPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Selling Price",
                prefixIcon: Icon(Icons.sell),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Stock Quantity",
                prefixIcon: Icon(Icons.storage),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addProduct,
              child: const Text("Add Product"),
            ),
          ],
        ),
      ),
    );
  }

}
