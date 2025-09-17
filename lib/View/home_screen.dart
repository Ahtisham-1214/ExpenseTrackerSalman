import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Database/app_database.dart';
import '../Database/product_dao.dart';
import '../Database/transaction_dao.dart';
import '../Database/ledger_dao.dart';
import '../Database/account_dao.dart';
import '../Model/product.dart';
import '../Model/account.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  int totalProducts = 0;
  double todaySales = 0.0;
  double totalSales = 0.0;
  double totalDebt = 0.0;
  double totalPurchases = 0.0;
  double totalReceivables = 0.0;
  double totalPayables = 0.0;
  int totalAccounts = 0;
  List<Product> topProducts = [];
  List<Map<String, dynamic>> accountBalances = [];
  bool isLoading = true;

  final _numberFormat = NumberFormat("#,##0.00", "en_PK");

  Future<void> loadStatistics() async {
    try {
      final db = await AppDatabase.instance.database;
      final productDao = ProductDao(db);
      final transactionDao = TransactionDao(db);
      final ledgerDao = LedgerDao(db);
      final accountDao = AccountDao(db);

      final productsCount = await productDao.getProductsCount();
      final todaySalesAmount = await transactionDao.getTodaySales();
      final totalSalesAmount = await transactionDao.getTotalSales();
      final debtAmount = await ledgerDao.getTotalDebt();
      final totalPurchasesAmount = await transactionDao.getTotalPurchases();
      final accounts = await accountDao.getAllAccounts();
      double receivables = 0.0;
      double payables = 0.0;
      List<Map<String, dynamic>> balances = [];
      for (final a in accounts) {
        final bal = await ledgerDao.getAccountBalance(a.id!);
        balances.add({'account': a, 'balance': bal});
        if (a.type == 'Customer' && bal > 0) receivables += bal;
        if (a.type == 'Supplier' && bal < 0) payables += bal.abs();
      }
      final products = await productDao.getAllProducts();
      final top = products.take(5).toList();

      setState(() {
        totalProducts = productsCount;
        todaySales = todaySalesAmount;
        totalSales = totalSalesAmount;
        totalDebt = debtAmount;
        totalPurchases = totalPurchasesAmount;
        totalAccounts = accounts.length;
        totalReceivables = receivables;
        totalPayables = payables;
        accountBalances = balances;
        topProducts = top;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading statistics: $e")));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  String formatCurrency(double amount) {
    return "${_numberFormat.format(amount)} Rs";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: loadStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: "Today Sale",
                      value: formatCurrency(todaySales),
                      icon: Icons.today,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: "Total Sale",
                      value: formatCurrency(totalSales),
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: "Total Products",
                      value: "$totalProducts",
                      icon: Icons.inventory,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: "Total Debt",
                      value: formatCurrency(totalDebt),
                      icon: Icons.money_off,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Financial Summary Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Financial Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Purchases',
                      value: formatCurrency(totalPurchases),
                      icon: Icons.shopping_cart,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Receivables',
                      value: formatCurrency(totalReceivables),
                      icon: Icons.account_balance_wallet,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Payables',
                      value: formatCurrency(totalPayables),
                      icon: Icons.payment,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Accounts',
                      value: '$totalAccounts',
                      icon: Icons.people,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Account Balances',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accountBalances.length,
                  itemBuilder: (context, index) {
                    final item = accountBalances[index];
                    final Account account = item['account'];
                    final double balance = item['balance'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          _accountIcon(account.type),
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(account.name),
                      subtitle: Text(account.type),
                      trailing: Text(
                        formatCurrency(balance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Top Products',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topProducts.length,
                  itemBuilder: (context, index) {
                    final product = topProducts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.1,
                        ),
                        child: Icon(
                          Icons.inventory,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text(product.category),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(product.sellingPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Stock: ${product.stockQuantity}',
                            style: TextStyle(
                              color:
                                  product.stockQuantity > 0
                                      ? Colors.green
                                      : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow:
                        TextOverflow.ellipsis, // 👈 prevent long text overflow
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _accountIcon(String type) {
    switch (type) {
      case 'Customer':
        return Icons.person;
      case 'Supplier':
        return Icons.business;
      case 'Income':
        return Icons.trending_up;
      case 'Expense':
        return Icons.trending_down;
      case 'Asset':
        return Icons.account_balance;
      case 'Walk-in':
        return Icons.directions_walk;
      default:
        return Icons.account_circle;
    }
  }
}
