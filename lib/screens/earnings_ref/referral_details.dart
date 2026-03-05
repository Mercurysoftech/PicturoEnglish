import 'package:flutter/material.dart';
import 'package:picturo_app/screens/premium_plans_screen.dart';
import 'package:share_plus/share_plus.dart';

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF49329A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 40,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF49329A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    "assets/bg_coins.png",
                    height: 120,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Refer your friends",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins Medium',
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Earn rewards on every referral",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins Medium',
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= REWARD INFO CARD =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF49329A).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Referral Rewards",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins Medium',
                        color: Color(0xFF49329A),
                      ),
                    ),
                    SizedBox(height: 12),

                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "₹300 (3-month call plan) → Earn ₹50",
                            style: TextStyle(fontFamily: 'Poppins Regular'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "₹360 (4-month call plan) → Earn ₹100",
                            style: TextStyle(fontFamily: 'Poppins Regular'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ================= HOW IT WORKS =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "How it works",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins Regular',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildProcessStep(
                    1,
                    "Friend installs the app",
                    "Share your referral code. Your friend installs the app using your code.",
                  ),
                  _buildProcessStep(
                    2,
                    "Friend subscribes",
                    "Your friend subscribes to a ₹300 or ₹360 call plan.",
                  ),
                  _buildProcessStep(
                    3,
                    "You earn rewards",
                    "Earn ₹50 for ₹300 plan or ₹100 for ₹360 plan after confirmation.",
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ================= FAQ =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "FAQ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins Medium',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        "How much can I earn per referral?",
                        style: TextStyle(fontFamily: 'Poppins Regular'),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "You earn ₹50 if your friend subscribes to the ₹300 plan, "
                            "and ₹100 if they choose the ₹360 plan.",
                            style: TextStyle(
                              color: Colors.black54,
                              fontFamily: 'Poppins Regular',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),

      // ================= BOTTOM ACTIONS =================
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF49329A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
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
                child: const Text(
                  "Check Out",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins Medium',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: const Color(0xFF49329A),
              radius: 26,
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  Share.share(
                    "Join me on Picturo English! "
                    "Earn rewards by subscribing to a call plan. "
                    "Download now from the Play Store.",
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildProcessStep(
    int index,
    String title,
    String subtitle, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF49329A),
              child: Text(
                "$index",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isLast)
              Container(
                height: 50,
                width: 2,
                color: Colors.grey,
              ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins Regular',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontFamily: 'Poppins Regular',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
