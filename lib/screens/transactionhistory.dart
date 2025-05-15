import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:picturo_app/screens/myprofilepage.dart';


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  List<WithdrawalTransaction> transactions = [];

  Future<void> fetchTransactions() async {
    final url = Uri.parse("http://picturoenglish.com/api/get_withdrawal_history.php");
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse["status"] == true && jsonResponse["data"] is List) {
        setState(() {
          transactions = (jsonResponse["data"] as List)
              .map((item) => WithdrawalTransaction.fromJson(item))
              .toList();
        });
      }
    } else {
      print('Failed to load transactions');
    }

    setState(() {
      isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
                Navigator.pop(context); // Replace with your desired back navigation
              },
            ),
          ),
          title: const Padding(
            padding: EdgeInsets.only(top: 15.0),
            child: Text(
              'Transaction History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins Regular',
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: transactions.isEmpty
            ? const Center(child: Text("No transactions found"))
            : ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final dateOnly = tx.requestedAt.split(" ").first;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == 0 || transactions[index - 1].requestedAt.split(" ").first != dateOnly) ...[
                  const SizedBox(height: 10),
                  Text(
                    dateOnly,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins Medium'),
                  ),
                  const Text(
                    '2025',
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins Medium'),
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: const Icon(Icons.remove, color: Colors.red),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Withdrew amount',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins Regular'),
                          ),
                          Text(
                            tx.requestedAt,
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins Regular'),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '₹${tx.amount}',
                        style: const TextStyle(fontSize: 16, color: Colors.red, fontFamily: 'Poppins Regular'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class WithdrawalTransaction {
  final int id;
  final String amount;
  final String paymentMethod;
  final String status;
  final String requestedAt;
  final String? processedAt;
  final String? rejectedAt;

  WithdrawalTransaction({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.rejectedAt,
  });

  factory WithdrawalTransaction.fromJson(Map<String, dynamic> json) {
    return WithdrawalTransaction(
      id: json['id'],
      amount: json['amount'],
      paymentMethod: json['payment_method'],
      status: json['status'],
      requestedAt: json['requested_at'],
      processedAt: json['processed_at'],
      rejectedAt: json['rejected_at'],
    );
  }
}