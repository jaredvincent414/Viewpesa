import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/transaction_models.dart';
import '../models/user_models.dart';

class DBHelper {
  static Database? _database;
  static const String _dbName = 'viewpesa.db';
  static const String _transactionTable = 'transactions';
  static const String _userTable = 'users';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_userTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phoneNumber TEXT UNIQUE,
            username TEXT,
            password TEXT NOT NULL -- Added password field, made it NOT NULL.
             imagePath TEXT -- Added imagePath field
          )
        ''');
        await db.execute('''
          CREATE TABLE $_transactionTable (
            id TEXT PRIMARY KEY,
            type TEXT,
            party TEXT,
            amount REAL,
            cost REAL,
            balance REAL,
            time TEXT,
            tag TEXT
          )
        ''');
      },
    );
  }
  // In dbhelper.dart (for testing)
  Future<void> insertTestTransaction() async {
    final testTransaction = TransactionModel(
      id: 'TEST123',
      type: 'M-PESA Received',
      party: 'John Doe',
      amount: 1000.0,
      cost: 10.0,
      balance: 5000.0,
      time: '2025-05-18 10:00 AM',
      tag: 'Salary',
    );
    await insertTransaction(testTransaction);
  }

  // User Operations
  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert(
      _userTable,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser(String phoneNumber) async {
    final db = await database;
    final maps = await db.query(
      _userTable,
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );
    if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
    return null;
  }

  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update(
      _userTable,
      user.toMap(),
      where: 'phoneNumber = ?',
      whereArgs: [user.phoneNumber],
    );
  }

  // Transaction Operations
  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert(_transactionTable, transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final maps = await db.query(_transactionTable);
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> searchTransactions(String query) async {
    final db = await database;
    final maps = await db.query(
      _transactionTable,
      where: 'party LIKE ? OR tag LIKE ? OR time LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.update(
      _transactionTable,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  //get user by ID.
  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      _userTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  // Add login function
  Future<UserModel?> login(String phoneNumber, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      _userTable,
      where: 'phoneNumber = ?', //  phoneNumber only
      whereArgs: [phoneNumber],
    );
    if (results.isNotEmpty) {
      final user = UserModel.fromMap(results.first);
      // Use bcrypt.check to compare the entered password with the stored hash.
      if (BCrypt.checkpw(password, user.password)) {
        return user;
      }
    }
    return null;
  }


}