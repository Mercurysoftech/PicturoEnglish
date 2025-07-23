import 'package:flutter/material.dart';
import '../../utils/common_app_bar.dart';

class WalletReferralPage extends StatefulWidget {
  @override
  _WalletReferralPageState createState() => _WalletReferralPageState();
}

class _WalletReferralPageState extends State<WalletReferralPage> {
  bool showBalance = true;
  final double balance = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "My Wallet", isBackbutton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFEDEAFF), // Light purple background
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Wallet and Referral Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF49329A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Wallet Balance",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            showBalance
                                ? "\$${balance.toStringAsFixed(2)}"
                                : "****",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => showBalance = !showBalance);
                            },
                            icon: Icon(
                              showBalance
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              showBalance ? "Hide" : "Show",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // Referral Count
                  Column(
                    children: [
                      Icon(Icons.group, color: Color(0xFF49329A)),
                      SizedBox(height: 8),
                      Text(
                        "Referrals",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "0",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF49329A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
