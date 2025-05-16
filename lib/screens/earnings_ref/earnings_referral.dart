import 'package:flutter/material.dart';

class WalletReferralPage extends StatefulWidget {
  @override
  _WalletReferralPageState createState() => _WalletReferralPageState();
}

class _WalletReferralPageState extends State<WalletReferralPage> {
  bool showBalance = true;
  final double balance = 00.0;

  final List<Map<String, String>> referredPersons = [
    // {"name": "John Doe", "email": "john@example.com"},
    // {"name": "Jane Smith", "email": "jane@example.com"},
    // {"name": "Alex Johnson", "email": "alex@example.com"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF49329A),
        title: Text("My Wallet", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Wallet Balance Card
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF49329A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    "Wallet Balance",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    showBalance ? "\$${balance.toStringAsFixed(2)}" : "****",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => showBalance = !showBalance);
                    },
                    icon: Icon(
                      showBalance ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white,
                    ),
                    label: Text(
                      showBalance ? "Hide Balance" : "Show Balance",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // Referrals Count
            Row(
              children: [
                Icon(Icons.group, color: Color(0xFF49329A)),
                SizedBox(width: 8),
                Text(
                  "Referrals: ${referredPersons.length}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF49329A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Referred Persons List
            ListView.builder(
              itemCount: referredPersons.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final person = referredPersons[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFF49329A),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(person['name']!),
                    subtitle: Text(person['email']!),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
