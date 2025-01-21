import 'package:flutter/material.dart';
import 'package:komunika/screens/bottom_nav_screen/botton_nav_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();  // Ensure proper initialization
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Komunika',
      home: BottomNavPage(),
    );
  }
}

