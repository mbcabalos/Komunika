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
    String path = join(await getDatabasesPath(), 'komunika_database.db');

    return await openDatabase(
      path,
      onCreate: (db, version) async {
        // Create the speech to text history tables
        await db.execute(
          'CREATE TABLE speech_to_text_history(id INTEGER PRIMARY KEY, title TEXT, content TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
        );

        // Create the text to speech history tables
        await db.execute(
          'CREATE TABLE text_to_speech_history(id INTEGER PRIMARY KEY, title TEXT, content TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS speech_to_text_history(id INTEGER PRIMARY KEY, title TEXT, content TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS text_to_speech_history(id INTEGER PRIMARY KEY, title TEXT, content TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
        );
      },
      version: 1,
    );
  }

  // =============================================
  // Speech-to-Text History Methods
  // =============================================

  Future<void> saveSpeechToTextHistory(String content) async {
    try {
      final db = await database;
      final words = content.trim().split(RegExp(r'\s+'));
      final title =
          words.length >= 3 ? words.sublist(0, 3).join(' ') : words.join(' ');
      await db.insert(
        'speech_to_text_history',
        {
          'title': title,
          'content': content,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Speech-to-Text history saved: $title');
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
    final db = await database;
    await db.delete('speech_to_text_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSpeechToTextHistoryTitle(int id, String newTitle) async {
    final db = await database;
    await db.update(
      'speech_to_text_history',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
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
  // Text-to-Speech History Methods
  // =============================================

  Future<void> saveTextToSpeechHistory(String content) async {
    try {
      final db = await database;
      final words = content.trim().split(RegExp(r'\s+'));
      final title =
          words.length >= 3 ? words.sublist(0, 3).join(' ') : words.join(' ');
      await db.insert(
        'text_to_speech_history',
        {
          'title': title,
          'content': content,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Text-to-Speech history saved: $title');
    } catch (e) {
      print('Error saving Text-to-Speech history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTextToSpeechHistory() async {
    try {
      final db = await database;
      return await db.query(
        'text_to_speech_history',
        orderBy: 'timestamp DESC',
      );
    } catch (e) {
      print('Error retrieving Text-to-Speech history: $e');
      return [];
    }
  }

  Future<void> deleteTextToSpeechHistory(int id) async {
    final db = await database;
    await db.delete('text_to_speech_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTextToSpeechHistoryTitle(int id, String newTitle) async {
    final db = await database;
    await db.update(
      'text_to_speech_history',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearTextToSpeechHistory() async {
    try {
      final db = await database;
      await db.delete('text_to_speech_history');
      print('All Text-to-Speech history cleared.');
    } catch (e) {
      print('Error clearing Text-to-Speech history: $e');
    }
  }
}
