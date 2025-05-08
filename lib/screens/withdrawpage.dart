import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picturo_app/providers/bankaccountprovider.dart';
import 'package:picturo_app/responses/bank_account_details.dart';
import 'package:picturo_app/screens/accountdetailsshow.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart'; // Import Dio for API calls

class WithdrawlAmountPage extends StatefulWidget {
  const WithdrawlAmountPage({super.key});

  @override
  State<WithdrawlAmountPage> createState() => _WithdrawlAmountPageState();
}

class _WithdrawlAmountPageState extends State<WithdrawlAmountPage> {
  TextEditingController banknum = TextEditingController();
  TextEditingController confirm = TextEditingController();
  TextEditingController ifsc = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController branch = TextEditingController();
  TextEditingController state = TextEditingController();
  TextEditingController amountController = TextEditingController();
  bool _isLoading = false;
  String? storedData;
  late ApiService _apiService; // Declare ApiService instance
  


  @override
  void initState() {
    super.initState();
    initializeApiService();
  }

   Future<void> initializeApiService() async {
    _apiService = await ApiService.create(); // Await the Future
  }

  Future<void> _submitWithdrawal() async {
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.sendWithdrawalRequest(
        amount: amountController.text,
        paymentMethod: 'bank_transfer', // or your payment method
      );

      if (!mounted) return;

      if (result.containsKey('status') == result.containsValue('success')) {
        // Success case
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Withdrawal request submitted'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Or navigate to another screen
      } else {
        // Error case
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to submit request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE7EAFF),
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
                  MaterialPageRoute(builder: (context) => MyProfileScreen()),
                );
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0), // Adjust top padding
            child: Row(
              children: [
                Text(
                  'Withdraw Money',
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
        padding: const EdgeInsets.all(20),
        child: Form(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter Amount', style: TextStyle(fontFamily: 'Poppins Regular')),
                SizedBox(height: 4),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF49329A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      "Withdraw",
                      style: TextStyle(color: Colors.white, fontFamily: 'Poppins Medium'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

