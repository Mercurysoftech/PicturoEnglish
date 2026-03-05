import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:picturo_app/providers/bankaccountprovider.dart';
import 'package:picturo_app/responses/bank_account_details.dart';
import 'package:picturo_app/screens/accountdetailsshow.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../utils/common_file.dart';

class WithdrawlAmountPage extends StatefulWidget {
  const WithdrawlAmountPage({super.key});

  @override
  State<WithdrawlAmountPage> createState() => _WithdrawlAmountPageState();
}

class _WithdrawlAmountPageState extends State<WithdrawlAmountPage> {
  TextEditingController amountController = TextEditingController();
  bool _isLoading = false;
  bool _isAccountVerified = true; // Assume verified by default
  bool _checkingAccountStatus = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    initializeApiService();
    // Optionally check account status on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _checkAccountVerificationStatus();
    });
  }

  Future<void> initializeApiService() async {
    _apiService = await ApiService.create();
  }

  // Method to check account verification status
  Future<void> _checkAccountVerificationStatus() async {
    setState(() {
      _checkingAccountStatus = true;
    });

    try {
      // You might want to have a separate API call to check account status
      // Or check it when user tries to withdraw
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _checkingAccountStatus = false;
        });
      }
    }
  }

  Future<void> _submitWithdrawal() async {
    // First check if amount is entered
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final enteredAmount = double.tryParse(amountController.text.trim()) ?? 0;
    if (enteredAmount < 500) { // Changed from <= 50 to < 500
      Fluttertoast.showToast(
        msg: "Minimum withdrawal amount is ₹500",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.sendWithdrawalRequest(
        amount: amountController.text,
        paymentMethod: 'bank_transfer',
      );

      if (!mounted) return;

      // Check if account is verified based on response
      if (result.containsKey('isaccountverified')) {
        setState(() {
          _isAccountVerified = result['isaccountverified'] == true;
        });
      }

      if (result.containsKey('status') && result['status'] == true) {
        // Success case
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Withdrawal request submitted'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (result['isaccountverified'] == false) {
        // Account not verified - show message but don't close dialog
        // The UI will show the account verification message based on _isAccountVerified
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Bank account details not found'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Other errors
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

  // Navigate to bank account details page
  void _navigateToBankAccountDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountDetailShow(), 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE7EAFF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0),
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
                // Show account verification message if account is not verified
                if (!_isAccountVerified)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Verification Required',
                          style: TextStyle(
                            fontFamily: 'Poppins Regular',
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Poppins Regular',
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'You need to provide your bank account details to withdraw. ',
                              ),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: _navigateToBankAccountDetails,
                                  child: Text(
                                    'Click here',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: ' to update your account information.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                Text('Enter Amount',
                    style: TextStyle(fontFamily: 'Poppins Regular')),
                SizedBox(height: 4),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: 'Enter amount in ₹',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 10),
                Text('Minimum Withdrawal Amount: ₹500',
                    style: TextStyle(
                        fontFamily: 'Poppins Regular',
                        color: Colors.redAccent)),
                
                // Show additional info if account not verified
                if (!_isAccountVerified)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Divider(color: Colors.grey[300]),
                      SizedBox(height: 10),
                      Text(
                        'Note:',
                        style: TextStyle(
                          fontFamily: 'Poppins Regular',
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Your withdrawal request will be processed only after your bank account is verified.',
                        style: TextStyle(
                          fontFamily: 'Poppins Regular',
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                
                SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAccountVerified 
                          ? Color(0xFF49329A) 
                          : Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Withdraw",
                            style: TextStyle(
                                color: _isAccountVerified 
                                    ? Colors.white 
                                    : Colors.grey[600],
                                fontFamily: AppConstants.commonFont,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                
                // Alternative: Add a button to navigate to bank details if not verified
                if (!_isAccountVerified)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _navigateToBankAccountDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text(
                          "Update Bank Account Details",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: AppConstants.commonFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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