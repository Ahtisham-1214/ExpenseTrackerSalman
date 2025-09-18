import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Database/app_database.dart';
import '../Database/product_dao.dart';
import '../Database/account_dao.dart';
import '../Database/transaction_dao.dart';
import '../Database/transaction_detail_dao.dart';
import '../Database/ledger_dao.dart';
import '../Model/product.dart';
import '../Model/account.dart';
import '../Model/app_transaction.dart';
import '../Model/transaction_detail.dart';
import '../Model/ledger_entry.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Product> _products = [];
  List<Account> _customers = [];
  List<CartItem> _cartItems = [];
  Account? _selectedCustomer;
  bool _isLoading = true;
  double _totalAmount = 0.0;

  final _numberFormat = NumberFormat("#,##0.00", "en_PK");

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = await AppDatabase.instance.database;
      final productDao = ProductDao(db);
      final accountDao = AccountDao(db);

      final products = await productDao.getAllProducts();
      final customers = await accountDao.getAllAccounts().then(
            (accounts) => accounts
            .where((a) => a.type == 'Customer' || a.type == 'Walk-in')
            .toList(),
      );

      setState(() {
        _products = products;
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e")),
        );
      }
    }
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex =
      _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex != -1) {
        _cartItems[existingIndex].quantity += 1;
      } else {
        _cartItems.add(CartItem(product: product, quantity: 1));
      }
      _calculateTotal();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _calculateTotal();
    });
  }

  void _updateQuantity(int index, double quantity) {
    if (quantity <= 0) {
      _removeFromCart(index);
    } else {
      setState(() {
        _cartItems[index].quantity = quantity;
        _calculateTotal();
      });
    }
  }

  void _calculateTotal() {
    _totalAmount = _cartItems.fold(
        0.0,
            (sum, item) =>
        sum + (item.product.sellingPrice * item.quantity));
  }

  Future<void> _processSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart is empty")),
      );
      return;
    }

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a customer")),
      );
      return;
    }

    try {
      final db = await AppDatabase.instance.database;
      final transactionDao = TransactionDao(db);
      final transactionDetailDao = TransactionDetailDao(db);
      final ledgerDao = LedgerDao(db);

      // Create transaction
      final transaction = AppTransaction(
        date: DateTime.now().toIso8601String(),
        type: 'Sale',
        accountId: _selectedCustomer!.id!,
        totalAmount: _totalAmount,
        remarks: 'POS Sale',
      );

      final transactionId =
      await transactionDao.insertTransaction(transaction);

      // Create transaction details and update stock
      for (final cartItem in _cartItems) {
        final detail = TransactionDetail(
          transactionId: transactionId,
          productId: cartItem.product.id!,
          quantity: cartItem.quantity,
          price: cartItem.product.sellingPrice,
        );
        await transactionDetailDao.insertTransactionDetail(detail);

        final updatedProduct = Product(
          id: cartItem.product.id,
          name: cartItem.product.name,
          category: cartItem.product.category,
          unit: cartItem.product.unit,
          purchasePrice: cartItem.product.purchasePrice,
          sellingPrice: cartItem.product.sellingPrice,
          stockQuantity:
          cartItem.product.stockQuantity - cartItem.quantity,
        );
        final productDao = ProductDao(db);
        await productDao.updateProduct(updatedProduct);
      }

      // Ledger entries
      await ledgerDao.insertLedgerEntry(LedgerEntry(
        transactionId: transactionId,
        accountId: _selectedCustomer!.id!,
        debit: 0.0,
        credit: _totalAmount,
      ));

      final salesAccount = _customers.firstWhere(
            (a) => a.name == 'Sales',
        orElse: () => Account(
          name: 'Sales',
          type: 'Income',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      if (salesAccount.id == null) {
        final accountDao = AccountDao(db);
        final salesAccountId = await accountDao.insertAccount(salesAccount);
        await ledgerDao.insertLedgerEntry(LedgerEntry(
          transactionId: transactionId,
          accountId: salesAccountId,
          debit: _totalAmount,
          credit: 0.0,
        ));
      } else {
        await ledgerDao.insertLedgerEntry(LedgerEntry(
          transactionId: transactionId,
          accountId: salesAccount.id!,
          debit: _totalAmount,
          credit: 0.0,
        ));
      }

      setState(() {
        _cartItems.clear();
        _totalAmount = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Sale completed successfully! Total: ${formatCurrency(_totalAmount)}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error processing sale: $e")),
        );
      }
    }
  }

  String formatCurrency(double amount) {
    return "${_numberFormat.format(amount)} Rs";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isNarrow = screenWidth < 800;
    final int crossAxisCount = isNarrow ? 2 : 3;

    Widget productsSection = Expanded(
      flex: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('Customer: '),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<Account>(
                    isExpanded: true,
                    value: _selectedCustomer,
                    hint: const Text('Select Customer'),
                    items: _customers
                        .map((customer) => DropdownMenuItem(
                              value: customer,
                              child: Text(
                                customer.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomer = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _addToCart(product),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.category,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            formatCurrency(product.sellingPrice),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Stock: ${product.stockQuantity}',
                            style: TextStyle(
                              color: product.stockQuantity > 0 ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    Widget cartPanel = Container(
      width: isNarrow ? double.infinity : 400,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  formatCurrency(_totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(
                    child: Text(
                      'Cart is empty',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = _cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(cartItem.product.name),
                          subtitle: Text(formatCurrency(cartItem.product.sellingPrice)),
                          trailing: FittedBox(
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => _updateQuantity(index, cartItem.quantity - 1),
                                  icon: const Icon(Icons.remove),
                                ),
                                Text('${cartItem.quantity.toInt()}'),
                                IconButton(
                                  onPressed: () => _updateQuantity(index, cartItem.quantity + 1),
                                  icon: const Icon(Icons.add),
                                ),
                                IconButton(
                                  onPressed: () => _removeFromCart(index),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatCurrency(_totalAmount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processSale,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Complete Sale',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: isNarrow
          ? Column(
              children: [
                productsSection,
                SizedBox(height: 360, child: cartPanel),
              ],
            )
          : Row(
              children: [
                productsSection,
                cartPanel,
              ],
            ),
    );
  }
}

class CartItem {
  final Product product;
  double quantity;

  CartItem({required this.product, required this.quantity});
}
