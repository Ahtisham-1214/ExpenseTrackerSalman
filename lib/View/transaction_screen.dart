import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Database/app_database.dart';
import '../Database/transaction_dao.dart';
import '../Database/account_dao.dart';
import '../Database/product_dao.dart';
import '../Database/ledger_dao.dart';
import '../Database/transaction_detail_dao.dart';
import '../Model/app_transaction.dart';
import '../Model/account.dart';
import '../Model/ledger_entry.dart';
import '../Model/product.dart';
import '../Model/transaction_detail.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _selectedType = 'Purchase';
  Account? _selectedAccount;

  List<Account> _accounts = [];
  List<Account> _suppliers = [];
  List<Account> _payableSuppliers = [];
  final Map<int, double> _accountBalanceById = {};

  List<Product> _products = [];
  List<TransactionItem> _transactionItems = [];

  final _remarksController = TextEditingController();
  final _paymentAmountController = TextEditingController();

  bool _isLoading = true;
  double _totalAmount = 0.0;

  final _numberFormat = NumberFormat("#,##0.00", "en_PK");
  final List<String> _transactionTypes = ['Purchase', 'Payment'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await AppDatabase.instance.database;
    final accountDao = AccountDao(db);
    final productDao = ProductDao(db);
    final ledgerDao = LedgerDao(db);

    final accounts = await accountDao.getAllAccounts();
    final products = await productDao.getAllProducts();

    final suppliers = accounts.where((a) => a.type == 'Supplier').toList();
    final payable = <Account>[];
    final balances = <int, double>{};
    for (final acc in suppliers) {
      final bal = await ledgerDao.getAccountBalance(acc.id!);
      balances[acc.id!] = bal;
      if (bal < 0) payable.add(acc);
    }

    setState(() {
      _accounts = accounts;
      _products = products;
      _suppliers = suppliers;
      _payableSuppliers = payable;
      _accountBalanceById
        ..clear()
        ..addAll(balances);
      _isLoading = false;
    });
  }

  void _addProduct(Product product) {
    setState(() {
      final idx = _transactionItems.indexWhere((i) => i.product.id == product.id);
      if (idx != -1) {
        _transactionItems[idx].quantity += 1;
      } else {
        _transactionItems.add(TransactionItem(
          product: product,
          quantity: 1,
          price: product.sellingPrice,
        ));
      }
      _calcTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _transactionItems.removeAt(index);
      _calcTotal();
    });
  }

  void _updateQuantity(int index, double qty) {
    setState(() {
      if (qty <= 0) {
        _transactionItems.removeAt(index);
      } else {
        _transactionItems[index].quantity = qty;
      }
      _calcTotal();
    });
  }

  void _updatePrice(int index, double price) {
    setState(() {
      _transactionItems[index].price = price;
      _calcTotal();
    });
  }

  void _calcTotal() {
    _totalAmount = _transactionItems.fold(
      0.0,
          (sum, item) => sum + item.price * item.quantity,
    );
  }

  String formatCurrency(double amount) => "${_numberFormat.format(amount)} Rs";

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Transactions')),
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(flex: 2, child: _buildLeftPanel()),
              SizedBox(width: constraints.maxWidth * 0.35, child: _buildRightPanel()),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(child: _buildLeftPanel()),
              SizedBox(height: constraints.maxHeight * 0.5, child: _buildRightPanel()),
            ],
          );
        }
      }),
    );
  }

  Widget _buildLeftPanel() {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Transaction type & account
            Row(
              children: [
                const Text('Type:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    items: _transactionTypes
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedType = v!;
                        _transactionItems.clear();
                        _totalAmount = 0.0;
                        _selectedAccount = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Account:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<Account>(
                    isExpanded: true,
                    value: _selectedAccount,
                    hint: const Text('Select'),
                    items: (_selectedType == 'Payment'
                        ? _payableSuppliers
                        : _suppliers)
                        .map((acc) => DropdownMenuItem(
                      value: acc,
                      child: Row(
                        children: [
                          Expanded(child: Text(acc.name)),
                          if (_selectedType == 'Payment')
                            Text(
                              '(${_accountBalanceById[acc.id!] ?? 0})',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 11),
                            )
                        ],
                      ),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAccount = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Product grid
            if (_selectedType == 'Purchase')
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, i) {
                    final p = _products[i];
                    return InkWell(
                      onTap: () => _addProduct(p),
                      child: Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                              Text(p.category,
                                  style: const TextStyle(fontSize: 11)),
                              const Spacer(),
                              Text(formatCurrency(p.sellingPrice),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary)),
                              Text('Stock: ${p.stockQuantity}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: p.stockQuantity > 0
                                          ? Colors.green
                                          : Colors.red)),
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
      ),
    );
  }

  Widget _buildRightPanel() {
    final theme = Theme.of(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // ✅ Themed Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: theme.colorScheme.primary,
                      child: Row(
                        children: [
                          Icon(Icons.receipt,
                              color: theme.colorScheme.onPrimary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Transaction Items',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatCurrency(_totalAmount),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ Items list
                    Expanded(
                      child: _transactionItems.isEmpty
                          ? Center(
                        child: Text(
                          'No items',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.all(6),
                        itemCount: _transactionItems.length,
                        itemBuilder: (context, index) {
                          final it = _transactionItems[index];
                          return Card(
                            color: theme.colorScheme.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          it.product.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme
                                                .colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _removeItem(index),
                                        icon: Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                              text: it.quantity.toString()),
                                          keyboardType:
                                          TextInputType.number,
                                          decoration:
                                          const InputDecoration(
                                            labelText: 'Qty',
                                            isDense: true,
                                          ),
                                          onChanged: (v) => _updateQuantity(
                                              index,
                                              double.tryParse(v) ?? 0),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(
                                              text: it.price.toString()),
                                          keyboardType:
                                          TextInputType.number,
                                          decoration:
                                          const InputDecoration(
                                            labelText: 'Price',
                                            isDense: true,
                                          ),
                                          onChanged: (v) => _updatePrice(
                                              index,
                                              double.tryParse(v) ?? 0),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Subtotal: ${formatCurrency(it.price * it.quantity)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                        theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ✅ Bottom inputs
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedType == 'Payment') ...[
                            TextField(
                              controller: _paymentAmountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Payment Amount',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: theme.colorScheme.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          TextField(
                            controller: _remarksController,
                            decoration: InputDecoration(
                              labelText: 'Remarks',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: theme.colorScheme.primary),
                              ),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface)),
                              Text(
                                formatCurrency(
                                  _selectedType == 'Payment'
                                      ? (double.tryParse(
                                      _paymentAmountController.text) ??
                                      0.0)
                                      : _totalAmount,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: (){

                            },
                            child: Text(_selectedType == 'Payment'
                                  ? 'Record Payment'
                                  : 'Process Purchase'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

class TransactionItem {
  final Product product;
  double quantity;
  double price;
  TransactionItem(
      {required this.product, required this.quantity, required this.price});
}
