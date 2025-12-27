import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_db.dart';

enum ExpenseFilterRange {
  day,
  week,
  month,
}

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider();

  final ExpenseDb _db = ExpenseDb.instance;

  List<Expense> _allExpenses = <Expense>[];
  bool _isLoading = false;
  bool _isDarkMode = false;
  ExpenseFilterRange _filterRange = ExpenseFilterRange.month;
  DateTime _selectedDate = DateTime.now();
  int? _currentUserId;

  List<Expense> get allExpenses => _allExpenses;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  ExpenseFilterRange get filterRange => _filterRange;
  DateTime get selectedDate => _selectedDate;
  int? get currentUserId => _currentUserId;

  Future<void> init(int userId) async {
    _currentUserId = userId;
    await _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (_currentUserId == null) return;
    _isLoading = true;
    notifyListeners();
    _allExpenses = await _db.getAllExpenses(_currentUserId!);
    _isLoading = false;
    notifyListeners();
  }

  List<Expense> get filteredExpenses {
    final now = _selectedDate;

    bool matchesRange(Expense e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      final selected = DateTime(now.year, now.month, now.day);

      switch (_filterRange) {
        case ExpenseFilterRange.day:
          return d == selected;
        case ExpenseFilterRange.week:
          final weekday = selected.weekday;
          final startOfWeek = selected.subtract(Duration(days: weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          return !d.isBefore(startOfWeek) && d.isBefore(endOfWeek);
        case ExpenseFilterRange.month:
          return d.year == selected.year && d.month == selected.month;
      }
    }

    return _allExpenses.where(matchesRange).toList();
  }

  double get totalForSelectedRange {
    return filteredExpenses.fold(
      0,
      (sum, e) => sum + e.amount,
    );
  }

  double get totalForToday {
    final today = DateTime.now();
    final todayOnly = _allExpenses.where((e) {
      final d = e.date;
      return d.year == today.year && d.month == today.month && d.day == today.day;
    });
    return todayOnly.fold(0, (sum, e) => sum + e.amount);
  }

  double get totalForCurrentMonth {
    final now = DateTime.now();
    final monthOnly = _allExpenses.where((e) {
      final d = e.date;
      return d.year == now.year && d.month == now.month;
    });
    return monthOnly.fold(0, (sum, e) => sum + e.amount);
  }

  void setFilterRange(ExpenseFilterRange range) {
    _filterRange = range;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    if (_currentUserId == null) return;
    // Ensure expense has the correct userId
    final expenseWithUserId = expense.userId == _currentUserId
        ? expense
        : expense.copyWith(userId: _currentUserId!);
    final id = await _db.insertExpense(expenseWithUserId);
    _allExpenses = <Expense>[
      Expense(
        id: id,
        userId: expenseWithUserId.userId,
        amount: expenseWithUserId.amount,
        category: expenseWithUserId.category,
        date: expenseWithUserId.date,
        note: expenseWithUserId.note,
      ),
      ..._allExpenses,
    ];
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) return;
    await _db.updateExpense(expense);
    _allExpenses = _allExpenses
        .map(
          (e) => e.id == expense.id ? expense : e,
        )
        .toList();
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    await _db.deleteExpense(id);
    _allExpenses = _allExpenses.where((e) => e.id != id).toList();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    if (_currentUserId == null) return;
    await _db.clearAll(_currentUserId!);
    _allExpenses = <Expense>[];
    notifyListeners();
  }

  void reset() {
    _currentUserId = null;
    _allExpenses = <Expense>[];
    _filterRange = ExpenseFilterRange.month;
    _selectedDate = DateTime.now();
    notifyListeners();
  }
}


