import 'package:flutter/material.dart';
import '../../Database/account_dao.dart';
import '../../Database/app_database.dart';
import '../../Model/account.dart';

class AccountList extends StatefulWidget {
  const AccountList({super.key});

  @override
  State<AccountList> createState() => _AccountListState();
}

class _AccountListState extends State<AccountList> {
  late Future<List<Account>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _accountsFuture = _fetchAccounts();
  }

  Future<List<Account>> _fetchAccounts() async {
    final db = await AppDatabase.instance.database;
    final accountDao = AccountDao(db);
    return accountDao.getAllAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Account>>(
      future: _accountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No accounts found"));
        }

        final accounts = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            return _buildAccountCard(account, context);
          },
        );
      },
    );
  }

  Widget _buildAccountCard(Account account, BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface, // ✅ use theme surface color
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Name + Type
            Row(
              children: [
                Icon(Icons.account_circle,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  account.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  account.type,
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // phone
            Row(
              children: [
                Icon(Icons.phone,
                    color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text("Phone: ${account.phoneNumber}",
                    style: textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),

            // Balance
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text("Balance: ${account.openingBalance}",
                    style: textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),

            // Created
            Row(
              children: [
                Icon(Icons.date_range,
                    color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text("Created: ${account.createdAt}",
                    style: textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),

            // Updated
            Row(
              children: [
                Icon(Icons.update,
                    color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text("Updated: ${account.updatedAt}",
                    style: textTheme.bodyMedium),
              ],
            ),

            // Popup Menu
            Row(
              children: [
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                      // TODO: Edit account
                        break;
                      case 'delete':
                      // TODO: Delete account
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
