import 'package:flutter/material.dart';
import 'package:komunika/screens/bottom_nav_screen/botton_nav_page.dart';
import 'package:komunika/screens/splash_screen/splash_screen.dart';
import 'package:path/path.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await checkDatabaseExistence();
  runApp(const MyApp());
}

Future<void> checkDatabaseExistence() async {
  String path = join(await getDatabasesPath(), 'audio_database.db');
  bool exists = await databaseExists(path);
  if (!exists) {
    await openDatabase(path, version: 1, onCreate: (db, version) {
      db.execute(
          'CREATE TABLE audio_items(id INTEGER PRIMARY KEY, audioName TEXT, favorites INTEGER DEFAULT 0)');
    });
    print('Database created');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => MaterialApp( //showcase widget builder context
        debugShowCheckedModeBanner: false,
        title: 'Komunika',
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const BottomNavPage(),
        },
      ),
    );
  }
}
