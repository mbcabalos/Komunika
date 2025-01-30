

import 'package:flutter/material.dart';
import 'package:komunika/screens/home_screen/home_page.dart';
import 'package:komunika/screens/navigation_screen/navigation_page.dart';
import 'package:komunika/screens/settings_screen/settings_page.dart';
import 'package:komunika/utils/colors.dart';

class BottomNavPage extends StatefulWidget {
  const BottomNavPage({super.key});

  @override
  State<BottomNavPage> createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<BottomNavPage> {
  int _currentPageIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const NavigationPage(),
    const SettingPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentPageIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: ColorsPalette.card,
        selectedItemColor: ColorsPalette.accent,
        unselectedItemColor: ColorsPalette.black, 
        currentIndex: _currentPageIndex,
        onTap: (index) {
          setState(() {
            _currentPageIndex = index; // Update the current index on tap
          });
        },
        
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Navigation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
