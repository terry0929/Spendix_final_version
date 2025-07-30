import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'transactions.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            isExpense INTEGER,
            amount REAL,
            note TEXT,
            date TEXT,
            isSaving INTEGER,
            savingAmount REAL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS transactions');
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            isExpense INTEGER,
            amount REAL,
            note TEXT,
            date TEXT,
            isSaving INTEGER,
            savingAmount REAL
          )
        ''');
      },
    );
  }

  Future<void> insertTransaction(TransactionModel model) async {
    final db = await database;
    await db.insert('transactions', model.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }
}
