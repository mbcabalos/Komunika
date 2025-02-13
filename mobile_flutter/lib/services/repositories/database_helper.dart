import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  List<Map<String, dynamic>> audioItems = [
    {'audioName': 'Hello', 'favorites': 1},
    {'audioName': 'Goodbye', 'favorites': 1},
    {'audioName': 'Greeting', 'favorites': 1},
  ];

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
        await moveAudioFiles();
        await insertAudioItems(audioItems);
      },
      version: 1,
    );
  }

  Future<void> moveAudioFiles() async {
    try {
      // Get the directory to store files in the app's "files" folder
      Directory? appDocDirectory = await getExternalStorageDirectory();
      String targetDir = '${appDocDirectory?.path}/audio';

      // Create the target folder if it doesn't exist
      final targetDirectory = Directory(targetDir);
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }

      // Define the list of audio file paths in assets
      List<String> assetFiles = [
        'assets/audio/Goodbye.mp3',
        'assets/audio/Greeting.mp3',
        'assets/audio/Hello.mp3',
      ];

      // Loop through each audio file, read it from assets and write it to the target folder
      for (String assetFile in assetFiles) {
        ByteData data = await rootBundle.load(assetFile);
        List<int> bytes = data.buffer.asUint8List();

        File file = File('$targetDir/${assetFile.split('/').last}');
        await file.writeAsBytes(bytes);
        print('File written to: ${file.path}');
      }
      insertAudioItems(audioItems);
    } catch (e) {
      print("Error moving audio files: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllAudioItems() async {
    final db = await database;
    return await db.query('audio_items');
  }

  Future<List<Map<String, dynamic>>> fetchAllFavorites() async {
    final db = await database;
    return await db.query(
      'audio_items',
      where: 'favorites = ?',
      whereArgs: [1],
    );
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

  Future<void> insertAudioItems(List<Map<String, dynamic>> audioItems) async {
    try {
      print("Inserting data...");
      final db = await database;

      // Loop through each item in the list and insert into the database
      for (var item in audioItems) {
        print("Inserting data now");
        await db.insert(
          'audio_items',
          item,
          conflictAlgorithm:
              ConflictAlgorithm.replace, // Handle conflicts by replacing
        );
      }

      print('Inserted all audio items');
      printDatabaseContent();
    } catch (e) {
      print('Error inserting audio items: $e');
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
