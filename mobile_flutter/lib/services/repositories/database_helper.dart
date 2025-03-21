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
    {'audioName': 'Greet', 'favorites': 1},
    {'audioName': 'Good morning', 'favorites': 1},
    {'audioName': 'Good afternoon', 'favorites': 1},
    {'audioName': 'Good evening', 'favorites': 1},
    {'audioName': 'Agree', 'favorites': 1},
    {'audioName': 'Disagree', 'favorites': 1},
    {'audioName': 'Sorry', 'favorites': 1},
    {'audioName': 'Thank you', 'favorites': 1},
    {'audioName': 'Ask the time', 'favorites': 1},
    {'audioName': 'Assistance', 'favorites': 1},
  ];

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    // <-- Add return type
    String path = join(await getDatabasesPath(), 'komunika_database.db');

    return await openDatabase(
      path,
      onCreate: (db, version) async {
        // Create the audio_items table
        await db.execute(
          'CREATE TABLE audio_items(id INTEGER PRIMARY KEY, audioName TEXT, favorites INTEGER DEFAULT 0)',
        );

        // Create the history tables
        await db.execute(
          'CREATE TABLE speech_to_text_history(id INTEGER PRIMARY KEY, text TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
        );
        await db.execute(
          'CREATE TABLE auto_caption_history(id INTEGER PRIMARY KEY, text TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
        );
        await db.execute(
          'CREATE TABLE sign_transcriber_history(id INTEGER PRIMARY KEY, text TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
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

      print('Target directory: $targetDir');

      // Create the target folder if it doesn't exist
      final targetDirectory = Directory(targetDir);
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }

      List<String> assetFiles = [
        'assets/audio/Goodbye.mp3',
        'assets/audio/Greet.mp3',
        'assets/audio/Hello.mp3',
        'assets/audio/Good morning.mp3',
        'assets/audio/Good afternoon.mp3',
        'assets/audio/Good evening.mp3',
        'assets/audio/Agree.mp3',
        'assets/audio/Disagree.mp3',
        'assets/audio/Start.mp3',
        'assets/audio/Sorry.mp3',
        'assets/audio/Thank you.mp3',
        'assets/audio/Ask the time.mp3',
        'assets/audio/Assistance.mp3',
      ];

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

  // =============================================
  // Audio Methods
  // =============================================

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
      limit: 5,
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

      // Ensure only the first five items are marked as favorites
      for (int i = 0; i < audioItems.length; i++) {
        audioItems[i]['favorites'] = i < 5 ? 1 : 0;

        await db.insert(
          'audio_items',
          audioItems[i],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('Inserted all audio items with favorites set.');
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

  // =============================================
  // Speech-to-Text History Methods
  // =============================================

  Future<void> saveSpeechToTextHistory(String text) async {
    try {
      final db = await database;
      await db.insert(
        'speech_to_text_history',
        {'text': text},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Speech-to-Text history saved: $text');
    } catch (e) {
      print('Error saving Speech-to-Text history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSpeechToTextHistory() async {
    try {
      final db = await database;
      return await db.query(
        'speech_to_text_history',
        orderBy: 'timestamp DESC',
      );
    } catch (e) {
      print('Error retrieving Speech-to-Text history: $e');
      return [];
    }
  }

  Future<void> deleteSpeechToTextHistory(int id) async {
    try {
      final db = await database;
      await db.delete(
        'speech_to_text_history',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Speech-to-Text history deleted: $id');
    } catch (e) {
      print('Error deleting Speech-to-Text history: $e');
    }
  }

  Future<void> clearSpeechToTextHistory() async {
    try {
      final db = await database;
      await db.delete('speech_to_text_history');
      print('All Speech-to-Text history cleared.');
    } catch (e) {
      print('Error clearing Speech-to-Text history: $e');
    }
  }

  // =============================================
  // Auto Caption History Methods
  // =============================================

  Future<void> saveAutoCaptionHistory(String text) async {
    try {
      final db = await database;
      await db.insert(
        'auto_caption_history',
        {'text': text},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Auto Caption history saved: $text');
    } catch (e) {
      print('Error saving Auto Caption history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAutoCaptionHistory() async {
    try {
      final db = await database;
      return await db.query(
        'auto_caption_history',
        orderBy: 'timestamp DESC',
      );
    } catch (e) {
      print('Error retrieving Auto Caption history: $e');
      return [];
    }
  }

  Future<void> deleteAutoCaptionHistory(int id) async {
    try {
      final db = await database;
      await db.delete(
        'auto_caption_history',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Auto Caption history deleted: $id');
    } catch (e) {
      print('Error deleting Auto Caption history: $e');
    }
  }

  Future<void> clearAutoCaptionHistory() async {
    try {
      final db = await database;
      await db.delete('auto_caption_history');
      print('All Auto Caption history cleared.');
    } catch (e) {
      print('Error clearing Auto Caption history: $e');
    }
  }

  // =============================================
  // Sign Transcriber History Methods
  // =============================================

  Future<void> saveSignTranscriberHistory(String text) async {
    try {
      final db = await database;
      await db.insert(
        'sign_transcriber_history',
        {'text': text},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Sign Transcriber history saved: $text');
    } catch (e) {
      print('Error saving Sign Transcriber history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSignTranscriberHistory() async {
    try {
      final db = await database;
      return await db.query(
        'sign_transcriber_history',
        orderBy: 'timestamp DESC',
      );
    } catch (e) {
      print('Error retrieving Sign Transcriber history: $e');
      return [];
    }
  }

  Future<void> deleteSignTranscriberHistory(int id) async {
    try {
      final db = await database;
      await db.delete(
        'sign_transcriber_history',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Sign Transcriber history deleted: $id');
    } catch (e) {
      print('Error deleting Sign Transcriber history: $e');
    }
  }

  Future<void> clearSignTranscriberHistory() async {
    try {
      final db = await database;
      await db.delete('sign_transcriber_history');
      print('All Sign Transcriber history cleared.');
    } catch (e) {
      print('Error clearing Sign Transcriber history: $e');
    }
  }
}
