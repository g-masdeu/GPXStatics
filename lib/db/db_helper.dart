import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../models/bike.dart';
import '../models/user.dart';
import '../models/route.dart'; // Ensure this import is correct

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = p.join(dir.path, 'app_data.db');
    final file = File(path);
    final db = sqlite3.open(file.path);
    _createTables(db);
    print('Database opened at $path');
    return db;
  }

  void _createTables(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        height INTEGER NOT NULL,
        weight INTEGER NOT NULL,
        gender TEXT NOT NULL,
        birthDate TEXT NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS bikes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        weight REAL NOT NULL
      );
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gpxContent TEXT NOT NULL,
        date TEXT,
        distanceKm REAL,
        elevationGainM REAL
      );
    ''');

    print('All tables ensured');
  }

  // ========== USER ==========
  Future<int> insertUser(User user) async {
    final db = await database;
    db.execute(
      '''
      INSERT INTO users (name, height, weight, gender, birthDate)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [
        user.name,
        user.height,
        user.weight,
        user.gender,
        user.birthDate.toIso8601String(),
      ],
    );
    return db.getUpdatedRows();
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final result = db.select('SELECT * FROM users;');
    return result.map((row) => User.fromMap({
          'id': row['id'],
          'name': row['name'],
          'height': row['height'],
          'weight': row['weight'],
          'gender': row['gender'],
          'birthDate': row['birthDate'],
        })).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    db.execute(
      '''
      UPDATE users SET name = ?, height = ?, weight = ?, gender = ?, birthDate = ?
      WHERE id = ?
      ''',
      [
        user.name,
        user.height,
        user.weight,
        user.gender,
        user.birthDate.toIso8601String(),
        user.id,
      ],
    );
    return db.getUpdatedRows();
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    db.execute('DELETE FROM users WHERE id = ?', [id]);
    return db.getUpdatedRows();
  }

  // ========== BIKE ==========
  Future<int> insertBike(Bike bike) async {
    final db = await database;
    db.execute(
      '''
      INSERT INTO bikes (brand, model, year, weight)
      VALUES (?, ?, ?, ?)
      ''',
      [bike.brand, bike.model, bike.year, bike.weight],
    );
    return db.getUpdatedRows();
  }

  Future<List<Bike>> getBikes() async {
    final db = await database;
    final result = db.select('SELECT * FROM bikes;');
    return result.map((row) => Bike.fromMap({
          'id': row['id'],
          'brand': row['brand'],
          'model': row['model'],
          'year': row['year'],
          'weight': row['weight'],
        })).toList();
  }

  Future<int> updateBike(Bike bike) async {
    final db = await database;
    db.execute(
      '''
      UPDATE bikes SET brand = ?, model = ?, year = ?, weight = ?
      WHERE id = ?
      ''',
      [bike.brand, bike.model, bike.year, bike.weight, bike.id],
    );
    return db.getUpdatedRows();
  }

  Future<int> deleteBike(int id) async {
    final db = await database;
    db.execute('DELETE FROM bikes WHERE id = ?', [id]);
    return db.getUpdatedRows();
  }

  // ========== ROUTES ==========
  Future<int> insertRoute(RouteData route) async {
    final db = await database;
    db.execute(
      '''
      INSERT INTO routes (name, gpxContent, date, distanceKm, elevationGainM)
      VALUES (?, ?, ?, ?, ?)
      ''',
      [
        route.name,
        route.gpxContent,
        route.date?.toIso8601String(),
        route.distanceKm,
        route.elevationGainM,
      ],
    );
    return db.getUpdatedRows();
  }

  Future<List<RouteData>> getRoutes() async {
    final db = await database;
    final result = db.select('SELECT * FROM routes;');
    return result.map((row) => RouteData.fromMap({
          'id': row['id'], // Include id when mapping from database
          'name': row['name'],
          'gpxContent': row['gpxContent'],
          'date': row['date'],
          'distanceKm': row['distanceKm'],
          'elevationGainM': row['elevationGainM'],
        })).toList();
  }

  Future<int> deleteRoute(int id) async {
    final db = await database;
    db.execute('DELETE FROM routes WHERE id = ?', [id]);
    return db.getUpdatedRows();
  }
}