import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:komunika/screens/home_screen/bottom_nav_screen.dart';
import 'package:komunika/screens/splash_screen/splash_screen.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/utils/app_localization.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/utils/themes.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SocketService socketService = SocketService();
  await checkDatabaseExistence();
  socketService.initSocket();
  String storedLanguage = await PreferencesUtils.getLanguage();
  Locale initialLocale =
      storedLanguage == 'Filipino' ? Locale('fil', 'PH') : Locale('en', 'US');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(initialLocale: initialLocale),
    ),
  );
}

Future<void> checkDatabaseExistence() async {
  String path = join(await getDatabasesPath(), 'komunika_database.db');
  // await deleteDatabase(path);
  bool exists = await databaseExists(path);
  if (!exists) {
    await openDatabase(path, version: 1, onCreate: (db, version) {
      // Create the speech to text history tables
      db.execute(
        'CREATE TABLE speech_to_text_history(id INTEGER PRIMARY KEY, title TEXT, content TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
      );
      // Create the text to speech history tables
      db.execute(
        'CREATE TABLE text_to_speech_history(id INTEGER PRIMARY KEY, title TEXT, content TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
      );
    });
    print('Database created');
  }
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;
  const MyApp({super.key, required this.initialLocale});

  static void setLocale(BuildContext context, Locale newLocale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  void setLocale(Locale locale) async {
    await PreferencesUtils.storeLanguage(
        locale.languageCode == 'fil' ? 'Filipino' : 'English');
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ShowCaseWidget(
      builder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Komunika',
        supportedLocales: const [
          Locale('en', 'US'), 
          Locale('fil', 'PH'), 
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: _locale,
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        themeMode: themeProvider.themeMode,
        theme: themeProvider.themeData,
        darkTheme: themeProvider.themeData,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => BottomNavScreen(
                themeProvider: themeProvider,
              ),
        },
      ),
    );
  }
}
