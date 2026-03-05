// subscription_dialog.dart
import 'package:flutter/material.dart';
import 'package:picturo_app/screens/premium_plans_screen.dart';
import 'package:picturo_app/utils/common_file.dart';
import 'package:lottie/lottie.dart'; // Add this import

class SubscriptionDialog extends StatelessWidget {
  const SubscriptionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEAE4FF),
              Color(0xFFE0F7FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF49329A).withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie Animation
            SizedBox(
              width: 120,
              height: 120,
              child: Lottie.asset(
                'assets/lottie/Premium_CallerID.json',
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Unlock Premium',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF49329A),
                fontFamily: AppConstants.commonFont,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  fontFamily: AppConstants.commonFont,
                  height: 1.5,
                ),
                children: const [
                  TextSpan(
                    text: 'You need to ',
                  ),
                  TextSpan(
                    text: 'subscribe',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF49329A),
                    ),
                  ),
                  TextSpan(
                    text: ' to any one of our plans to ',
                  ),
                  TextSpan(
                    text: 'continue learning',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF49329A),
                    ),
                  ),
                  TextSpan(
                    text: ' and unlock all features.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Buttons
            Row(
              children: [
                // OK Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: Color(0xFF49329A),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF49329A),
                        fontFamily: AppConstants.commonFont,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Subscribe Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PremiumPlansScreen(
                            isChatBot: false,
                            isCall: false,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF49329A),
                      elevation: 5,
                      shadowColor: const Color(0xFF49329A).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        // Icon(
                        //   Icons.star,
                        //   color: Colors.white,
                        //   size: 20,
                        // ),
                        SizedBox(width: 8),
                        Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: AppConstants.commonFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Static method to show the dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Can't dismiss by tapping outside
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Can't dismiss with back button
        child: const SubscriptionDialog(),
      ),
    );
  }
}
