import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  // Get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;

    // If the database is not initialized, create it
    _database = await _initDatabase();  // Wait for the database to be created
    return _database!;  // Return the created database
  }


  // Initialize the database
  Future<Database> _initDatabase() async {  // <-- Add return type
  String path = join(await getDatabasesPath(), 'audio_database.db');

  return await openDatabase(
    path,
    onCreate: (db, version) async {
      // Create the table with id and audioPath
      await db.execute(
        'CREATE TABLE audio_items(id INTEGER PRIMARY KEY, audioPath TEXT)',
      );
    },
    version: 1,  // First version
  );
}


  // Insert an audio item (just the audioPath for now)
  Future<void> insertAudioItem(String audioPath) async {
    try {
      final db = await database;
      await db.insert(
        'audio_items',
        {'audioPath': audioPath},
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
        print('id: ${row['id']}, audioPath: ${row['audioPath']}');
      }
    } catch (e) {
      print('Error printing database content: $e');
    }
  }


  // Update an audio item's path (if needed)
  Future<void> updateAudioItem(int id, String audioPath) async {
    final db = await database;
    await db.update(
      'audio_items',
      {'audioPath': audioPath},
      where: 'id = ?',
      whereArgs: [id],
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