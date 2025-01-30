import 'package:flutter/material.dart';
import 'package:komunika/screens/home_screen/home_page.dart';
import 'package:komunika/screens/splash_screen/splash_screen.dart';
import 'package:komunika/utils/themes.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await checkDatabaseExistence();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> checkDatabaseExistence() async {
  String path = join(await getDatabasesPath(), 'audio_database.db');
  await deleteDatabase(path);
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ShowCaseWidget(
      builder: (context) => MaterialApp(
        //showcase widget builder context
        debugShowCheckedModeBanner: false,
        title: 'Komunika',
        theme: themeProvider.themeData,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}
