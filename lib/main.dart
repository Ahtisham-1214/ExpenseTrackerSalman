import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salman_expense/View/setting_screen.dart';
import 'package:salman_expense/View/spalsh_screen.dart';
import 'Database/app_database.dart';
import 'View/account_screen.dart';
import 'View/home_screen.dart';
import 'View/inventory_screen.dart';
import 'View/ledger_screen.dart';
import 'View/sales_screen.dart';
import 'View/transaction_screen.dart';
import 'View/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeProvider.primaryColor),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _bottomNavPages = const [
    HomeScreen(),
    SalesScreen(),
    LedgerScreen(),
    TransactionScreen(),
  ];

  Widget _currentPage = const HomeScreen();

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _currentPage = _bottomNavPages[index];
    });
  }

  void _onDrawerItemTapped(Widget page) {
    setState(() {
      _currentPage = page;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text("Inventory"),
              onTap: () => _onDrawerItemTapped(const InventoryScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Account"),
              onTap: () => _onDrawerItemTapped(const AccountScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () => _onDrawerItemTapped(const SettingsScreen()),
            ),
          ],
        ),
      ),
      body: _currentPage,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Ledger'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Transaction'),
        ],
      ),
    );
  }
}
