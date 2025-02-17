import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_walkthrough/walkthrough_bloc.dart';
import 'package:komunika/utils/shared_prefs.dart';

class HomeWalkthrough extends StatefulWidget {
  const HomeWalkthrough({super.key});

  @override
  State<HomeWalkthrough> createState() => _HomeWalkthroughState();
}

class _HomeWalkthroughState extends State<HomeWalkthrough> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _imagePaths = [
    'assets/walkthrough/intro_1.png', // Replace with your image paths
    'assets/walkthrough/intro_2.png',
    'assets/walkthrough/intro_3.png',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    if (_currentPage < _imagePaths.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _markWalkthroughCompleted(); // Automatically mark as done on last page
    }
  }

  void _skipWalkthrough() async {
    await PreferencesUtils.storeWalkthrough(true); // Skip and mark as done
    Navigator.of(context).pop(); // Close the walkthrough dialog
  }

  void _markWalkthroughCompleted() async {
    await PreferencesUtils.storeWalkthrough(true); // Mark as completed
    Navigator.of(context).pop(); // Close the walkthrough dialog
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _imagePaths.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return Center(
                    child: Image.asset(_imagePaths[index]), // Displaying image
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _imagePaths.length,
                (index) => _buildIndicator(index),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip Button
                TextButton(
                  onPressed: _skipWalkthrough,
                  child: Text('Skip'),
                ),
                // Next Button or Done Button
                ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _imagePaths.length - 1 ? 'Done' : 'Next',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: _currentPage == index ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
