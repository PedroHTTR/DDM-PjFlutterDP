import 'package:sqflite/sqflite.dart';

import 'database_factory.dart';
import '../models/expense.dart';
import '../models/user.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  static const _databaseName = 'ddm_finance.db';
  static const _databaseVersion = 1;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    configureDatabaseFactory();

    _database = await openDatabase(
      _databaseName,
      version: _databaseVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            budget REAL NOT NULL DEFAULT 0
          )
        ''');
        await database.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            amount REAL NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      },
    );
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<bool> registerUser({
    required String username,
    required String password,
    required double budget,
  }) async {
    final database = await this.database;
    final existing = await database.query(
      'users',
      columns: ['id'],
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;

    await database.insert('users', {
      'username': username,
      'password': password,
      'budget': budget,
    });
    return true;
  }

  Future<User?> authenticate({
    required String username,
    required String password,
  }) async {
    final database = await this.database;
    final rows = await database.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<User?> getUser(String username) async {
    final database = await this.database;
    final rows = await database.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<List<Expense>> getExpenses(int userId) async {
    final database = await this.database;
    final rows = await database.query(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<Expense?> getExpense(int userId, int expenseId) async {
    final database = await this.database;
    final rows = await database.query(
      'expenses',
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, expenseId],
      limit: 1,
    );
    return rows.isEmpty ? null : Expense.fromMap(rows.first);
  }

  Future<Expense> createExpense({
    required int userId,
    required String category,
    required String description,
    required double amount,
  }) async {
    final database = await this.database;
    final id = await database.insert('expenses', {
      'user_id': userId,
      'category': category,
      'description': description,
      'amount': amount,
      'created_at': DateTime.now().toIso8601String(),
    });
    return (await getExpense(userId, id))!;
  }

  Future<bool> updateExpense(Expense expense) async {
    final database = await this.database;
    final updated = await database.update(
      'expenses',
      {
        'category': expense.category,
        'description': expense.description,
        'amount': expense.amount,
      },
      where: 'user_id = ? AND id = ?',
      whereArgs: [expense.userId, expense.id],
    );
    return updated > 0;
  }

  Future<bool> deleteExpense(int userId, int expenseId) async {
    final database = await this.database;
    final deleted = await database.delete(
      'expenses',
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, expenseId],
    );
    return deleted > 0;
  }

  Future<int> deleteAllExpenses(int userId) async {
    final database = await this.database;
    return database.delete(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
