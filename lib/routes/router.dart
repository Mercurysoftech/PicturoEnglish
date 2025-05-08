import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picturo_app/screens/genderandagepage.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/screens/locationgetpage.dart';
import 'package:picturo_app/screens/loginscreen.dart';
import 'package:picturo_app/screens/splashscreenpage.dart';
import 'package:shared_preferences/shared_preferences.dart';


Future<String> getInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final genderDetailsDone = prefs.getBool('genderDetailsDone') ?? false;
  final locationDone = prefs.getBool('locationDone') ?? false;

  if (!isLoggedIn) {
    return '/login';
  } else {
    return '/home';
  }
}

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/gender', builder: (context, state) => const GenderAgeScreen()),
    GoRoute(path: '/location', builder: (context, state) => const LocationGetPage()),
    GoRoute(path: '/home', builder: (context, state) => const Homepage()),
  ],
);
