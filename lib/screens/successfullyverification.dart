import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:picturo_app/screens/genderandagepage.dart';

import '../utils/common_file.dart'; // Import the Lottie package
// Import animation library

class SuccessfullyVerification extends StatefulWidget {
  const SuccessfullyVerification({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SuccessfullyVerificationState createState() => _SuccessfullyVerificationState();
}

class _SuccessfullyVerificationState extends State<SuccessfullyVerification> with TickerProviderStateMixin {
  late AnimationController _animationController; // Animation controller for Lottie animation

  @override
  void initState() {
    super.initState();
    // Initialize the AnimationController with vsync (this allows animations to be efficient)
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _animationController.dispose(); // Don't forget to dispose the controller to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Add the Lottie animation widget here
            Lottie.asset(
              'assets/lottie/Lottie Successful.json',  // Path to the animation file
              width: 200,  // Adjust width
              height: 200,  // Adjust height
              fit: BoxFit.cover,  // Adjust the fit type as needed
              controller: _animationController, // Use the controller
              onLoaded: (composition) {
                // Once the animation is loaded, start it and set the animation to loop once
                _animationController.forward(); // Play the animation once
              },
            ),
            const Text(
              'Successfully',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: AppConstants.commonFont,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your account has been created',
              style: TextStyle(
                fontSize: 14,
                fontFamily: AppConstants.commonFont,
              ),
            ),
            const SizedBox(height: 20),
            Align(
  alignment: Alignment.center,
  child: ElevatedButton( 
    onPressed: () {
      // Add your next action here, such as navigating to another page
      Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => GenderAgeScreen()),
                                    );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF49329A),
      minimumSize: const Size(200, 50), // Set a fixed width for the button
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: const Text(
      'Okey',
      style: TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontFamily: AppConstants.commonFont,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

          ],
        ),
      ),
    );
  }
}
