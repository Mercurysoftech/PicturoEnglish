// offline_overlay.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:picturo_app/classes/services/connectivity_service.dart';
import 'package:provider/provider.dart';


class OfflineOverlay extends StatelessWidget {
  const OfflineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = Provider.of<ConnectivityService>(context);
    final bool isOnline = connectivityService.isOnline;

    if (isOnline) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/no_internet.json',
                width: 250,
                height: 250,
              ),
              const SizedBox(height: 16),
              const Text(
                'No internet connection',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins Medium',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your connection and try again',
                style: TextStyle(
                  color: Colors.black54,
                  fontFamily: 'Poppins Regular',
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}