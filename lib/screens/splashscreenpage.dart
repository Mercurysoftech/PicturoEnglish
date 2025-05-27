import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:picturo_app/screens/loginscreen.dart';
import 'package:picturo_app/screens/homepage.dart';

import 'introduction_animation/introduction_animation_screen.dart'; // Import your homepage

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLowEndDevice = false;
  String _displayText = "";
  final String _fullText = "VOCABULARY LEARNING THROUGH PICTURES AND VISUALS";
  Timer? _typingTimer;
  int _typingIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _startTypingAnimation();

    // Delay splash and check user login status
    Future.delayed(const Duration(seconds: 3), () {
      _checkLoginStatus();
    });
  }

  // Simulate user login status check using SharedPreferences
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {

     bool? isFirst= prefs.getBool("isFirstTime");
     if(isFirst==false){
       Navigator.of(context).pushReplacement(
         MaterialPageRoute(
           builder: (context) => isLoggedIn ? const Homepage() : const LoginScreen(),
         ),
       );
     }else{
       Navigator.of(context).pushReplacement(
         MaterialPageRoute(
           builder: (context) => IntroductionAnimationScreen(),
         ),
       );
     }


    }
  }

  void _startTypingAnimation() {
    const typingSpeed = Duration(milliseconds: 25);
    _typingTimer = Timer.periodic(typingSpeed, (timer) {
      if (_typingIndex < _fullText.length) {
        setState(() {
          _displayText = _fullText.substring(0, _typingIndex + 1);
          _typingIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isLowEndDevice = MediaQuery.of(context).size.shortestSide < 360;

    return Scaffold(
      backgroundColor: const Color(0xFF231065),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Image.asset(
                  'assets/Picturo English.png',
                  width: _isLowEndDevice ? 120 : 160,
                  height: _isLowEndDevice ? 120 : 160,
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _animation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _displayText,
                    style: TextStyle(
                      fontSize: _isLowEndDevice ? 8: 12,
                      color: Colors.white,
                      fontFamily: 'Poppins Regular',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
