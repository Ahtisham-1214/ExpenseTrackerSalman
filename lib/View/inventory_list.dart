import 'package:flutter/material.dart';
import '/Database/app_database.dart';
import '/Database/product_dao.dart';
import '/Model/product.dart';

class InventoryList extends StatefulWidget {
  const InventoryList({super.key});

  @override
  InventoryListState createState() => InventoryListState(); // 👈 make state public
}

class InventoryListState extends State<InventoryList> {
  List<Product> _products = [];

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
        final bool isLowStock = product.stockQuantity > 0 && product.stockQuantity < 10;
        final bool isOutOfStock = product.stockQuantity == 0;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), // Reduced vertical margin
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () {
              print("Tapped on ${product.name}");
              // TODO: Navigate to product detail or show more info
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Important for compact height
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28, // Slightly larger main icon
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
                      // Stock Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: isOutOfStock
                                ? Colors.red.shade100
                                : isLowStock
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isOutOfStock
                                    ? Colors.red.shade300
                                    : isLowStock
                                    ? Colors.orange.shade300
                                    : Colors.green.shade300,
                                width: 0.5
                            )
                        ),
                        child: Text(
                          "${product.stockQuantity} stock",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isOutOfStock
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
                        isLabelBold: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4), // Smaller spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCompactDetailItem(
                          context,
                          icon: Icons.sell_outlined,
                          label: "Sell: PKR ${product.sellingPrice.toStringAsFixed(2)}",
                          isLabelBold: true,
                          labelColor: Theme.of(context).colorScheme.primary
                      ),
                      // You can add purchase price here if space allows, or show on tap/detail
                      // _buildCompactDetailItem(
                      //   context,
                      //   icon: Icons.shopping_cart_checkout_outlined,
                      //   label: "Buy: PKR ${product.purchasePrice.toStringAsFixed(2)}",
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Helper for compact detail items
  Widget _buildCompactDetailItem(BuildContext context, {required IconData icon, required String label, bool isLabelBold = false, Color? labelColor}) {
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



  // @override
//   Widget build(BuildContext context) {
//     if (_products.isEmpty) {
//       return const Center(child: Text("No products available"));
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(12),
//       itemCount: _products.length,
//       itemBuilder: (context, index) {
//         final product = _products[index];
//         return Card(
//           elevation: 4, // Slightly increased elevation for better shadow
//           margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//           shape: RoundedRectangleBorder( // Adds rounded corners
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: InkWell( // Makes the card tappable
//             onTap: () {
//               // TODO: Handle item tap, e.g., navigate to product details
//               print("Tapped on ${product.name}");
//               // Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)));
//             },
//             borderRadius: BorderRadius.circular(12), // Match card's border radius
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       CircleAvatar( // A more visually appealing leading element
//                         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
//                         child: Icon(
//                           Icons.inventory_2_outlined, // Or a more specific icon if available
//                           color: Theme.of(context).colorScheme.onPrimaryContainer,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Text(
//                           product.name,
//                           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                           overflow: TextOverflow.ellipsis, // Handle long names
//                         ),
//                       ),
//                       // Optional: Action icon like 'edit' or 'more_vert'
//                       // Icon(Icons.more_vert, color: Colors.grey[600]),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   const Divider(), // Visual separator
//                   const SizedBox(height: 12),
//                   _buildProductDetailRow(
//                     context,
//                     icon: Icons.category_outlined,
//                     label: "Category",
//                     value: product.category,
//                   ),
//                   _buildProductDetailRow(
//                     context,
//                     icon: Icons.straighten_outlined, // Icon for unit/measurement
//                     label: "Unit",
//                     value: product.unit,
//                   ),
//                   _buildProductDetailRow(
//                     context,
//                     icon: Icons.shopping_cart_checkout_outlined, // Icon for purchase price
//                     label: "Purchase Price",
//                     value: "PKR ${product.purchasePrice.toStringAsFixed(2)}", // Assuming PKR currency
//                   ),
//                   _buildProductDetailRow(
//                     context,
//                     icon: Icons.sell_outlined, // Icon for selling price
//                     label: "Selling Price",
//                     value: "PKR ${product.sellingPrice.toStringAsFixed(2)}", // Assuming PKR currency
//                   ),
//                   _buildProductDetailRow(
//                     context,
//                     icon: product.stockQuantity > 0
//                         ? Icons.store_mall_directory_outlined // Icon for in stock
//                         : Icons.warning_amber_rounded, // Icon for out of stock or low stock
//                     label: "Stock Quantity",
//                     value: product.stockQuantity.toString(),
//                     valueColor: product.stockQuantity > 0
//                         ? (product.stockQuantity < 10 ? Colors.orange.shade700 : Colors.green.shade700) // Low stock warning
//                         : Colors.red.shade700, // Out of stock
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
// // Helper widget to build consistent detail rows
//   Widget _buildProductDetailRow(BuildContext context, {required IconData icon, required String label, required String value, Color? valueColor}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
//           const SizedBox(width: 12),
//           Expanded(
//             flex: 2, // Give more space to label
//             child: Text(
//               "$label:",
//               style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                   color: Colors.grey[700],
//                   fontWeight: FontWeight.w500
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 3, // Give more space to value
//             child: Text(
//               value,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 fontWeight: FontWeight.w600,
//                 color: valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }


}
