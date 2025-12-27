import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/user_db.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _loadCurrentUser();
  }

  final UserDb _userDb = UserDb.instance;
  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');
      if (userId != null) {
        _currentUser = await _userDb.getUserById(userId);
      }
    } catch (e) {
      // Handle error silently
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String name) async {
    try {
      final user = await _userDb.getUserByName(name);
      if (user == null) {
        return false; // User not found
      }
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', user.id!);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String name, double budget) async {
    try {
      // Check if user already exists
      final existingUser = await _userDb.getUserByName(name);
      if (existingUser != null) {
        return false; // User already exists
      }

      final user = User(name: name, budget: budget);
      final id = await _userDb.insertUser(user);
      _currentUser = User(id: id, name: name, budget: budget);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', id);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    notifyListeners();
  }

  Future<void> updateUserBudget(double budget) async {
    if (_currentUser == null || _currentUser!.id == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(budget: budget);
      await _userDb.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}

