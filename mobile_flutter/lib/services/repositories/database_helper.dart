import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    // <-- Add return type
    String path = join(await getDatabasesPath(), 'audio_database.db');

    return await openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE audio_items(id INTEGER PRIMARY KEY, audioName TEXT, favorites INTEGER DEFAULT 0)',
        );
      },
      version: 1,
    );
  }

  Future<List<Map<String, dynamic>>> fetchAllAudioItems() async {
    final db = await database;
    return await db.query('audio_items');
  }

  // Insert an audio item (just the audioName for now)
  Future<void> insertAudioItem(String audioName) async {
    try {
      final db = await database;
      await db.insert(
        'audio_items',
        {'audioName': audioName, 'favorites': 0},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      printDatabaseContent();
    } catch (e) {
      print('Error inserting audio item: $e');
    }
  }

  Future<void> printDatabaseContent() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query('audio_items');

      // Print each row from the database
      for (var row in result) {
        print('id: ${row['id']}, audioName: ${row['audioName']}');
      }
    } catch (e) {
      print('Error printing database content: $e');
    }
  }

  // Update an audio item's path (if needed)
  Future<void> updateAudioItem(int id, String audioName) async {
    final db = await database;
    await db.update(
      'audio_items',
      {'audioName': audioName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> favorite(String audioName) async {
    final db = await database;
    await db.update(
      'audio_items',
      {'favorites': 1},
      where: 'audioName = ?',
      whereArgs: [audioName],
    );
  }

  Future<void> removeFavorite(String audioName) async {
    final db = await database;
    await db.update(
      'audio_items',
      {'favorites': 0},
      where: 'audioName = ?',
      whereArgs: [audioName],
    );
  }

  // Delete an audio item
  Future<void> deleteAudioItem(int id) async {
    final db = await database;
    await db.delete(
      'audio_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
