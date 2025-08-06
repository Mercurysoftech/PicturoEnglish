import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cubits/referal_cubit/referal_cubit.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletTransaction {
  final double amount;
  final String type;
  final String description;
  final String createdAt;

  WalletTransaction({
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      amount: double.parse(json['amount'].toString()),
      type: json['type'],
      description: json['description'],
      createdAt: json['created_at'],
    );
  }
}

class WalletReferralPage extends StatefulWidget {
  @override
  _WalletReferralPageState createState() => _WalletReferralPageState();
}

class _WalletReferralPageState extends State<WalletReferralPage> {
  bool showBalance = true;
  List<WalletTransaction> transactions = [];

  @override
  void initState() {
    super.initState();
    context.read<ReferralCubit>().fetchReferralEarnings();
    fetchWalletTransactions();
  }


  Future<void> fetchWalletTransactions() async {
    final url = Uri.parse('https://picturoenglish.com/api/wallet-transaction.php');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<dynamic> txs = data['transactions'];
      setState(() {
        transactions = txs.map((tx) => WalletTransaction.fromJson(tx)).toList();
      });
    } else {
      print("❌ Failed to fetch transactions: ${response.statusCode} - ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "My Wallet",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF49329A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<ReferralCubit, ReferralState>(
        builder: (context, state) {
          if (state is ReferralLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ReferralLoaded) {
            final data = state.earnings;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEAFF),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF49329A),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Wallet Balance",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      showBalance
                                          ? "₹${data.totalEarned.toStringAsFixed(2)}"
                                          : "****",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () => setState(() => showBalance = !showBalance),
                                      icon: Icon(
                                        showBalance ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      label: Text(
                                        showBalance ? "Hide" : "Show",
                                        style: const TextStyle(color: Colors.white),
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
                            const SizedBox(width: 16),
                            Column(
                              children: [
                                const Icon(Icons.group, color: Color(0xFF49329A)),
                                const SizedBox(height: 8),
                                const Text(
                                  "Referrals",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${data.totalReferrals}",
                                  style: const TextStyle(
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
                  
                  const SizedBox(height: 24),
                  Text("Last Transaction",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
                  const SizedBox(height: 10,),
                  (transactions.isEmpty)?
                      Text("No transaction found"):ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100
                        ),
                        child: ListTile(
                          title: Text(tx.description),
                          subtitle: Text(tx.createdAt),
                          trailing: Text(
                            "+ ₹${tx.amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: tx.type == "referral" ? Colors.green : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          } else if (state is ReferralError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          return const SizedBox();
        },
      ),
    );
  }
}
