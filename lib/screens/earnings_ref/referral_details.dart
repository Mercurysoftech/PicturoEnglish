import 'package:flutter/material.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/screens/premium_plans_screen.dart';
import 'package:picturo_app/utils/sharedPrefsService.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF49329A),
        leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      toolbarHeight: 40,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16.0),
  decoration: const BoxDecoration(
    color: Color(0xFF49329A), // purple background
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(30),
      bottomRight: Radius.circular(30),
    ),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start, // align text to top
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Left side: Texts
      Image.asset(
        "assets/bg_coins.png",
        height: 120,
        fit: BoxFit.fill,
      ),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text(
              "Refer your friends",
              style: TextStyle(
                fontSize: 21,
                fontFamily: 'Poppins Medium',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Earn ₹100 each",
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins Medium',
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),

      // Right side: Image
      
    ],
  ),
),


            //const SizedBox(height: 20),

            // // Reward card
            // Card(
            //   margin: const EdgeInsets.symmetric(horizontal: 20),
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   elevation: 4,
            //   child: Padding(
            //     padding: const EdgeInsets.all(20),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: const [
            //         Text(
            //           "TOTAL REWARD",
            //           style: TextStyle(
            //             fontSize: 16,
            //             fontFamily: 'Poppins Medium',
            //             fontWeight: FontWeight.w600,
            //           ),
            //         ),
            //         Text(
            //           "₹300",
            //           style: TextStyle(
            //             fontSize: 22,
            //             fontFamily: 'Poppins Medium',
            //             fontWeight: FontWeight.bold,
            //             color: Color(0xFF6A4CE0),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            const SizedBox(height: 30),

            // How it works section
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
                        fontFamily: 'Poppins Regular'),
                  ),
                  const SizedBox(height: 20),
                 _buildProcessStep(
  1,
  "Friend installs the app",
  "Share your referral link. Your friend installs the app with your referral code.",
),
_buildProcessStep(
  2,
  "Friend subscribes",
  "Your friend must subscribe to a plan of ₹300 or above and enter your referral code at checkout.",
),
_buildProcessStep(
  3,
  "You earn ₹100",
  "You’ll get ₹100 credited once your friend’s subscription is confirmed and the return period is over.",
  isLast: true,
),


                ],
              ),
            ),

            const SizedBox(height: 30),

            // FAQ section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "FAQ",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Poppins Medium',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      title: const Text(
                        "What is the Refer and Earn program?",
                        style: TextStyle(
                            fontSize: 16, fontFamily: 'Poppins Regular'),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "It’s a program where you invite friends and earn ₹100 once they place their first order.",
                            style: TextStyle(
                                color: Colors.black54,
                                fontFamily: 'Poppins Regular'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10,),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        "When will I receive my reward?",
                        style: TextStyle(
                            fontSize: 16, fontFamily: 'Poppins Regular'),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "You’ll receive it after your friend’s order return period ends.",
                            style: TextStyle(
                                color: Colors.black54,
                                fontFamily: 'Poppins Regular'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
       bottomNavigationBar: Padding(
  padding: const EdgeInsets.all(16.0),
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
              MaterialPageRoute(builder: (context) => const PremiumPlansScreen()),
            );
          },
          child: const Text(
            "Check Out",
            style: TextStyle(
                fontSize: 16, fontFamily: 'Poppins Medium', color: Colors.white),
          ),
        ),
      ),
      const SizedBox(width: 12),
      CircleAvatar(
        backgroundColor: const Color(0xFF49329A),
        radius: 26,
        child: IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
         // In your ReferralPage, modify the share button:
onPressed: () async {
  String? referralCode = await SharedPrefsService.getReferralCode();
  
  if (referralCode != null && referralCode.isNotEmpty) {
    const playStoreLink = "https://play.google.com/store/apps/details?id=com.picturo.picturoenglish";
    Share.share("Hey! Join me on this app using my referral code: $referralCode. Download here: $playStoreLink");
  } else {
    // Try to get it from the provider if not in SharedPreferences
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    if (profileProvider.referralCode != null && profileProvider.referralCode!.isNotEmpty) {
      const playStoreLink = "https://play.google.com/store/apps/details?id=com.picturo.picturoenglish";
      Share.share("Hey! Join me on this app using my referral code: ${profileProvider.referralCode!}. Download here: $playStoreLink");
      
      // Also save it for future use
      await SharedPrefsService.saveReferralCode(profileProvider.referralCode!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Referral code not available')),
      );
    }
  }
},
        ),
      )
    ],
  ),
),
    );
  }

  Widget _buildProcessStep(int index, String title, String subtitle, {bool isLast = false}) {
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if (!isLast)
            Container(
              height: 50,
              width: 2,
              color: Colors.grey.shade400,
            ),
        ],
      ),
      const SizedBox(width: 15),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins Regular')),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      color: Colors.black54, fontFamily: 'Poppins Regular')),
            ],
          ),
        ),
      )
    ],
  );
}

}
