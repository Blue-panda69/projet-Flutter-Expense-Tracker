import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';

class UserDb {
  UserDb._internal();

  static final UserDb instance = UserDb._internal();

  static const _dbName = 'expenses.db';
  static const _dbVersion = 2; // Incremented for user table

  static const _tableUsers = 'users';

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
        // Create users table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_tableUsers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            budget REAL NOT NULL
          )
        ''');
        // Create expenses table if it doesn't exist
        await db.execute('''
          CREATE TABLE IF NOT EXISTS expenses (
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
          // Add users table if upgrading from version 1
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_tableUsers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              budget REAL NOT NULL
            )
          ''');
          // Add user_id column to expenses table if it doesn't exist
          try {
            await db.execute('ALTER TABLE expenses ADD COLUMN user_id INTEGER');
          } catch (e) {
            // Column might already exist, ignore
          }
        }
      },
    );
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query(_tableUsers, orderBy: 'id DESC');
    return maps.map((m) => User.fromMap(m)).toList();
  }

  Future<User?> getUserByName(String name) async {
    final db = await database;
    final maps = await db.query(
      _tableUsers,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableUsers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return db.insert(_tableUsers, user.toMap());
  }

  Future<int> updateUser(User user) async {
    if (user.id == null) {
      throw ArgumentError('User id is required for update');
    }
    final db = await database;
    return db.update(
      _tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return db.delete(
      _tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

