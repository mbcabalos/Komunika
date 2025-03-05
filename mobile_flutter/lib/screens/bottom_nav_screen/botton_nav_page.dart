

import 'package:flutter/material.dart';
import 'package:komunika/screens/home_screen/home_page.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/themes.dart';

class BottomNavPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const BottomNavPage({super.key, required this.themeProvider});

  @override
  State<BottomNavPage> createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<BottomNavPage> {
  int _currentPageIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
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
