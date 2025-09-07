// inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:salman_expense/View/inventory_list.dart';
import 'inventory_form.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final GlobalKey<InventoryListState> _listKey = GlobalKey<InventoryListState>();

  void _refreshList() {
    _listKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Inventory",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 2,
          backgroundColor: theme.colorScheme.primary,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TabBar(
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onPrimary.withOpacity(0.7),
                indicator: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.add, size: 20), text: "Add Product"),
                  Tab(icon: Icon(Icons.list, size: 20), text: "View Product"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            InventoryForm(onProductAdded: _refreshList),
            InventoryList(key: _listKey),
          ],
        ),
      ),
    );
  }
}
