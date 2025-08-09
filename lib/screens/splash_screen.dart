import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_3/screens/login_screen.dart';
import 'package:flutter_application_3/main.dart'; // Import MainScreen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    print('Splash screen initialized');

    try {
      // Initialize the animation controller with duration
      _controller = AnimationController(
        duration: Duration(seconds: 2),
        vsync: this,
      );
      print('Animation controller initialized');

      // Define the opacity animation (fade-in effect)
      _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      );

      // Define the scale animation (logo grows slightly)
      _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      print('Animations defined');

      // Start the animation when the screen is shown
      _controller.forward();
      print('Animation started');

      // Check user authentication after the animation
      Future.delayed(Duration(seconds: 3), () {
        print('Checking user login status...');
        _checkUserLoginStatus();
      });
    } catch (e) {
      print('Error in splash screen initialization: $e');
      // Navigate to login screen on error
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    }
  }

  void _checkUserLoginStatus() {
    try {
      print('Getting current user...');
      User? user = FirebaseAuth.instance.currentUser;
      print('Current user: ${user?.email ?? 'None'}');

      if (user != null) {
        // User is logged in, navigate to MainScreen
        print('User is logged in, navigating to MainScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        // No user logged in, navigate to LoginScreen
        print('No user logged in, navigating to LoginScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      print('Error checking user login status: $e');
      // Navigate to login screen on error
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green, // Background color for the splash screen
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/nutriselect.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
