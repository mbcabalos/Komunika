import 'package:flutter/material.dart';
import 'package:komunika/utils/fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), 
    );

    // Fade-in animation
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward(); // Start the animation

    // Navigate to the next screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, 
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Icon
              Image.asset(
                'assets/icons/logo.png',
                width: 100,
                height: 100,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),

              const SizedBox(height: 20),
              // App Name or Tagline
              Text(
                'Komunika',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: getResponsiveFontSize(context, 25),
                  fontWeight: FontWeight.bold,
                  fontFamily: Fonts.main,
                  letterSpacing: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double getResponsiveFontSize(BuildContext context, double size) {
    double baseWidth = 375.0; // Reference width (e.g., iPhone 11 Pro)
    double screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / baseWidth);
  }
}
