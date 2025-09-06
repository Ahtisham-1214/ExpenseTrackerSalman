import 'package:sqflite/sqflite.dart';

import '/Model/account.dart';

class AccountDao {
  final Database db; // injected when you open DB

  AccountDao(this.db);

  Future<int> insertAccount(Account account) async {
    return await db.insert('Accounts', account.toMap());
  }

  Future<List<Account>> getAllAccounts() async {
    final result = await db.query('Accounts');
    return result.map((map) => Account.fromMap(map)).toList();
  }

  Future<Account?> getAccountById(int id) async {
    final result = await db.query(
      'Accounts',
      where: 'account_id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Account.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateAccount(Account account) async {
    return await db.update(
      'Accounts',
      account.toMap(),
      where: 'account_id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    return await db.delete(
      'Accounts',
      where: 'account_id = ?',
      whereArgs: [id],
    );
  }
}
