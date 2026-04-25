import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  static const String _key = 'transactions';

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  List<TransactionModel> get sortedTransactions {
    final list = [..._transactions];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      _transactions =
          decoded.map((item) => TransactionModel.fromMap(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_transactions.map((t) => t.toMap()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    _transactions.add(transaction);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _saveToPrefs();
    notifyListeners();
  }
}
