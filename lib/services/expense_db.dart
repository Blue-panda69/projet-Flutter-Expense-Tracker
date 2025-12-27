import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

class ExpenseDb {
  ExpenseDb._internal();

  static final ExpenseDb instance = ExpenseDb._internal();

  static const _dbName = 'expenses.db';
  static const _dbVersion = 2; // Incremented for user_id column

  static const _tableExpenses = 'expenses';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Create users table if it doesn't exist
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            budget REAL NOT NULL
          )
        ''');
        // Create expenses table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_tableExpenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            category INTEGER NOT NULL,
            date INTEGER NOT NULL,
            note TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add user_id column to expenses table
          try {
            await db.execute('ALTER TABLE $_tableExpenses ADD COLUMN user_id INTEGER');
            // Set default user_id to 1 for existing expenses (if any)
            await db.execute('UPDATE $_tableExpenses SET user_id = 1 WHERE user_id IS NULL');
          } catch (e) {
            // Column might already exist, ignore
          }
        }
      },
    );
  }

  Future<List<Expense>> getAllExpenses(int userId) async {
    final db = await database;
    final maps = await db.query(
      _tableExpenses,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert(_tableExpenses, expense.toMap());
  }

  Future<int> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw ArgumentError('Expense id is required for update');
    }
    final db = await database;
    return db.update(
      _tableExpenses,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete(
      _tableExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll(int userId) async {
    final db = await database;
    await db.delete(
      _tableExpenses,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}


