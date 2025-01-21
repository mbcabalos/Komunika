

import 'package:flutter/material.dart';
import 'package:komunika/screens/home_screen/home_page.dart';
import 'package:komunika/screens/settings_screen/setting_page.dart';
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
    const SettingPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentPageIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: ColorsPalette.black.withOpacity(0.6),
        selectedItemColor: ColorsPalette.white, // Color for the selected item
        unselectedItemColor: ColorsPalette.grey, // Color for the unselected items
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
            icon: Icon(Icons.category_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
