import 'package:flutter/material.dart';
import '/Database/account_dao.dart';
import '/Database/app_database.dart';
import '/Model/account.dart';

class AccountForm extends StatefulWidget {
  const AccountForm({super.key});

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _typeController = TextEditingController();
  final _types = ['Supplier', 'Customer', 'Income', 'Expense'];

  Future<void> _validateAccount() async {
    if (_formKey.currentState!.validate()) {
      try {
        final accountName = _accountNameController.text;
        final openingBalance = double.tryParse(_openingBalanceController.text) ?? 0.0;
        final date = _dateController.text.isEmpty ? DateTime.now().toString().split(" ")[0] : _dateController.text;
        final time = _timeController.text.isEmpty ? TimeOfDay.now().format(context) : _timeController.text;
        final type = _typeController.text;

        Account account = Account(
          name: accountName,
          type: type,
          openingBalance: openingBalance,
          createdAt: "$date $time",
        );

        final accountDao = AccountDao(await AppDatabase.instance.database);
        await accountDao.insertAccount(account);

        _accountNameController.clear();
        _openingBalanceController.clear();
        _dateController.clear();
        _timeController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _accountNameController,
              decoration: const InputDecoration(
                labelText: "Name",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value == null || value.isEmpty ? "Please enter the account holder name" : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _openingBalanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Opening Balance",
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Type",
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              value: _typeController.text.isEmpty ? null : _typeController.text,
              items: _types.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
                }).toList(),
              onChanged: (value) {
                setState(() {
                  _typeController.text = value!;
                });
                },
              validator: (value) =>
              value == null || value.isEmpty ? "Please select the account type" : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Date",
                prefixIcon: Icon(Icons.date_range),
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  _dateController.text = picked.toString().split(" ")[0];
                }
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _timeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Time",
                prefixIcon: Icon(Icons.access_time),
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  _timeController.text = picked.format(context);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _validateAccount,
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}
