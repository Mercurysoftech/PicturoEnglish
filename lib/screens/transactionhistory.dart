import 'package:flutter/material.dart';
import 'package:picturo_app/screens/myprofilepage.dart';


class TransactionHistoryPage extends StatelessWidget {
  TransactionHistoryPage({super.key});

  final List<Map<String, dynamic>> transactions = [
    {'date': '19 March', 'type': 'Credited', 'amount': 100, 'isCredit': true},
    {'date': '19 March', 'type': 'Withdrew', 'amount': 100, 'isCredit': false},
    {'date': '19 March', 'type': 'Credited', 'amount': 100, 'isCredit': true},
    {'date': '19 March', 'type': 'Withdrew', 'amount': 100, 'isCredit': false},
    {'date': '20 March', 'type': 'Credited', 'amount': 100, 'isCredit': true},
    {'date': '20 March', 'type': 'Withdrew', 'amount': 100, 'isCredit': false},
    {'date': '20 March', 'type': 'Credited', 'amount': 100, 'isCredit': true},
    {'date': '20 March', 'type': 'Withdrew', 'amount': 100, 'isCredit': false},
    {'date': '20 March', 'type': 'Withdrew', 'amount': 200, 'isCredit': false},
    {'date': '20 March', 'type': 'Withdrew', 'amount': 1000, 'isCredit': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
     appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // Increased app bar height
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0), // Adjust top padding
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
               Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyProfileScreen(),
                    ),
                  );
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0), // Adjust top padding
            child: Row(
              children: [
                Text(
                  'Transaction History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins Regular',
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  bool isFirstOfDate = index == 0 || transactions[index - 1]['date'] != transaction['date'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10,),
                      if (isFirstOfDate) ...[
                        Text(
                          transaction['date'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,fontFamily: 'Poppins Medium'),
                        ),
                        const Text(
                          '2025',
                          style: TextStyle(fontSize: 12, color: Colors.grey,fontFamily: 'Poppins Medium'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: transaction['isCredit'] ? Colors.green.shade100 : Colors.red.shade100,
                              child: Icon(
                                transaction['isCredit'] ? Icons.add : Icons.remove,
                                color: transaction['isCredit'] ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${transaction['type']} amount',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500,fontFamily: 'Poppins Regular'),
                                ),
                                Text(
                                  transaction['date'],
                                  style: const TextStyle(fontSize: 12, color: Colors.grey,fontFamily: 'Poppins Regular'),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              '₹${transaction['amount']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins Regular',
                                color: transaction['isCredit'] ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10,)
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
