import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shop.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      // you can also add onUpgrade for migrations
    );
  }

  Future _createDB(Database db, int version) async {
    // Create Accounts table
    await db.execute('''
      CREATE TABLE Accounts (
        account_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT CHECK(type IN ('Supplier', 'Customer','Asset','Income','Expense', 'Walk-in')) NOT NULL,
        opening_balance REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        phone_number TEXT
      )
    ''');

    // ✅ Insert Walk-in account by default
    await db.insert(
      'Accounts',
      {'name': 'Walk-in', 'type': 'Walk-in', 'opening_balance': 0},
      conflictAlgorithm: ConflictAlgorithm.ignore, // in case it's already there
    );

    // trigger to auto-update `updated_at` whenever a row changes
    await db.execute('''
  CREATE TRIGGER update_accounts_updated_at
  AFTER UPDATE ON Accounts
  FOR EACH ROW
  BEGIN
    UPDATE Accounts SET updated_at = CURRENT_TIMESTAMP WHERE account_id = OLD.account_id;
  END;
''');

    // Create Products table
    await db.execute('''
      CREATE TABLE Products (
        product_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        unit TEXT,
        purchase_price REAL,
        selling_price REAL,
        stock_quantity REAL DEFAULT 0
      )
    ''');

    // Create Transactions table
    await db.execute('''
      CREATE TABLE Transactions (
        transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT DEFAULT CURRENT_TIMESTAMP,
        type TEXT CHECK(type IN ('Purchase','Sale','Payment','Receipt')) NOT NULL,
        account_id INTEGER NOT NULL,
        total_amount REAL,
        remarks TEXT,
        FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
      )
    ''');

    // Create TransactionDetails table
    await db.execute('''
      CREATE TABLE TransactionDetails (
        detail_id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER,
        product_id INTEGER,
        quantity REAL,
        price REAL,
        FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id),
        FOREIGN KEY (product_id) REFERENCES Products(product_id)
      )
    ''');

    // Create Ledger table
    await db.execute('''
      CREATE TABLE Ledger (
        ledger_id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER,
        account_id INTEGER,
        debit REAL DEFAULT 0,
        credit REAL DEFAULT 0,
        FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id),
        FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
