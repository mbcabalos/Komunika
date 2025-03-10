import 'package:flutter/material.dart';
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
    'assets/images/welcome.jpg', 
    'assets/images/stt5.jpg',
    'assets/images/vm5.jpg',
    'assets/images/st5.jpg',
    'assets/images/sc5.jpg',
    'assets/images/s5.jpg',

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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _markWalkthroughCompleted();
    }
  }

  void _skipWalkthrough() async {
    await PreferencesUtils.storeWalkthrough(true);
    Navigator.of(context).pop();
  }

  void _markWalkthroughCompleted() async {
    await PreferencesUtils.storeWalkthrough(true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12), 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with fixed size to fit dialog
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
              height: MediaQuery.of(context).size.height * 0.5, // 50% of screen height
              child: PageView.builder(
                controller: _pageController,
                itemCount: _imagePaths.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _imagePaths[index],
                      fit: BoxFit.cover, // Ensures image fits well
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _imagePaths.length,
                (index) => _buildIndicator(index),
              ),
            ),
            const SizedBox(height: 12),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _skipWalkthrough,
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(_currentPage == _imagePaths.length - 1 ? 'Done' : 'Next'),
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
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
