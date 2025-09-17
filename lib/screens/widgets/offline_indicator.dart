// offline_indicator.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.grey[800],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/no_internet.json', 
            width: 24,
            height: 24,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 8),
          const Text(
            'You\'re offline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}