import 'package:flutter/material.dart';
import 'package:komunika/screens/home_screen/home_page.dart';
import 'package:komunika/screens/splash_screen/splash_screen.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/utils/themes.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SocketService socketService = SocketService();
  await socketService.initSocket();
  await checkDatabaseExistence();
  await requestPermissions();

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

Future<void> requestPermissions() async {
  var status = await Permission.microphone.request();
  if (status.isDenied || status.isPermanentlyDenied) {
    print("Microphone permission is required!");
    // Optionally, guide the user to the app settings to enable it
    openAppSettings();
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
