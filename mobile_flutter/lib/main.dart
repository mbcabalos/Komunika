import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:komunika/screens/home_screen/home_page.dart';
import 'package:komunika/screens/splash_screen/splash_screen.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization.dart';
import 'package:komunika/utils/shared_prefs.dart';
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

List<Map<String, dynamic>> audioItems = [
  {'audioName': 'Hello', 'favorites': 1},
  {'audioName': 'Goodbye', 'favorites': 1},
  {'audioName': 'Greet', 'favorites': 1},
];

Future<void> checkDatabaseExistence() async {
  DatabaseHelper databaseHelper = DatabaseHelper();
  String path = join(await getDatabasesPath(), 'audio_database.db');
  await deleteDatabase(path);
  bool exists = await databaseExists(path);
  if (!exists) {
    await openDatabase(path, version: 1, onCreate: (db, version) {
      db.execute(
          'CREATE TABLE audio_items(id INTEGER PRIMARY KEY, audioName TEXT, favorites INTEGER DEFAULT 0)');
    });
    databaseHelper.moveAudioFiles();
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
        //showcase widget builder context
        debugShowCheckedModeBanner: false,
        title: 'Komunika',
        supportedLocales: const [
          Locale('en', 'US'), // English
          Locale('fil', 'PH'), // Filipino
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
