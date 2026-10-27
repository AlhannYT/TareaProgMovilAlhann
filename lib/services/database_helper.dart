import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';

/// Helper singleton para la gestión de persistencia local en SQLite.
/// Almacena los usuarios favoritos para permitir el acceso offline sin conexión a Internet.
class DatabaseHelper {
  static const String _databaseName = 'user_directory.db';
  static const int _databaseVersion = 1;

  static const String tableFavorites = 'favorites';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnUsername = 'username';
  static const String columnEmail = 'email';
  static const String columnPhone = 'phone';
  static const String columnWebsite = 'website';
  static const String columnCompanyName = 'companyName';

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableFavorites (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnUsername TEXT NOT NULL,
        $columnEmail TEXT NOT NULL,
        $columnPhone TEXT NOT NULL,
        $columnWebsite TEXT NOT NULL,
        $columnCompanyName TEXT NOT NULL
      )
    ''');
  }

  /// Inserta o reemplaza un usuario en la tabla de favoritos.
  Future<int> insertFavorite(UserModel user) async {
    final db = await database;
    return await db.insert(
      tableFavorites,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Elimina un usuario de favoritos dado su [id].
  Future<int> removeFavorite(int id) async {
    final db = await database;
    return await db.delete(
      tableFavorites,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  /// Recupera todos los usuarios almacenados localmente como favoritos.
  Future<List<UserModel>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableFavorites,
      orderBy: '$columnName ASC',
    );

    return maps.map((map) => UserModel.fromMap(map)).toList();
  }

  /// Verifica si un usuario con el [id] especificado ya está guardado en favoritos.
  Future<bool> isFavorite(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      tableFavorites,
      columns: [columnId],
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Cierra la base de datos si es necesario.
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
