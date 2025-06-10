import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picturo_app/providers/bankaccountprovider.dart';
import 'package:picturo_app/responses/bank_account_details.dart';
import 'package:picturo_app/screens/accountdetailsshow.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../utils/common_file.dart'; // Import Dio for API calls

class VerifyBankAccount extends StatefulWidget {
  const VerifyBankAccount({super.key});

  @override
  State<VerifyBankAccount> createState() => _VerifyBankAccountState();
}

class _VerifyBankAccountState extends State<VerifyBankAccount> {
  TextEditingController banknum = TextEditingController();
  TextEditingController confirm = TextEditingController();
  TextEditingController ifsc = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController branch = TextEditingController();
  TextEditingController state = TextEditingController();
  String? storedData;
  late ApiService _apiService; // Declare ApiService instance

  @override
  void initState() {
    super.initState();
    getData();
    initializeApiService();
  }

   Future<void> initializeApiService() async {
    _apiService = await ApiService.create(); // Await the Future
  }

  Future<void> datastore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (banknum.text.trim().isNotEmpty) {
      await prefs.setString('action', banknum.text.trim());
      getData();
    } else {
      print('Bank number is empty!');
    }
  }

  Future<void> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedData = prefs.getString('action') ?? "No data saved";
    });
  }
  Future<void> postBankAccount() async {
  if (banknum.text.isEmpty || 
      confirm.text.isEmpty || 
      name.text.isEmpty || 
      ifsc.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please fill in all the fields"))
    );
    return;
  }

  if (banknum.text != confirm.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Account numbers do not match"))
    );
    return;
  }

  try {
    Map<String, dynamic> response = await _apiService.postBankAccount(
      accountNumber: banknum.text.trim(),
      confrimAccountNumber: confirm.text.trim(),
      accountHolderName: name.text.trim(),  // Assuming `branch` holds bank name
      ifscCode: ifsc.text.trim(),
    );

    print('accountNumber:${banknum.text.trim()}');

    if (response["status"] == "success") {
      // Save data in provider
    Provider.of<BankAccountProvider>(context, listen: false)
        .setBankAccountDetails(response["account_details"]);

        // Save data in SharedPreferences
        await _saveBankDetailsToSharedPreferences(response["account_details"]);
        
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bank account verified successfully!"))
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AccountDetailShow()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["error"] ?? "Verification failed"))
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Something went wrong. Please try again."))
    );
  }
}

 // Save bank details to SharedPreferences
  Future<void> _saveBankDetailsToSharedPreferences(Map<String, dynamic> accountDetails) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('accountNumber', accountDetails['account_number'] ?? '');
    await prefs.setString('accountHolderName', accountDetails['account_holder_name'] ?? '');
    await prefs.setString('ifscCode', accountDetails['ifsc_code'] ?? '');
    await prefs.setString('branch', accountDetails['branch_name'] ?? '');
    await prefs.setString('bank_name', accountDetails['bank_name'] ?? '');
    await prefs.setString('micr', accountDetails['micr'] ?? '');
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
                  MaterialPageRoute(builder: (context) => AccountDetailShow()),
                );
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0), // Adjust top padding
            child: Row(
              children: [
                Text(
                  'Verify bank account',
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
                Text('Account Number', style: TextStyle(fontFamily: 'Poppins Regular')),
                SizedBox(height: 4),
                TextField(
                  controller: banknum,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                SizedBox(height: 10),
                Text('Confirm Account Number', style: TextStyle(fontFamily: 'Poppins Regular')),
                SizedBox(height: 4),
                TextField(
                  controller: confirm,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                SizedBox(height: 10),
                Text('Account Holder Name', style: TextStyle(fontFamily: 'Poppins Regular')),
                SizedBox(height: 4),
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                SizedBox(height: 10),
                Text('IFSC Code', style: TextStyle(fontFamily: 'Poppins Regular')),
                SizedBox(height: 4),
                TextField(
                  controller: ifsc,
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
                    onPressed: () {
                      postBankAccount();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF49329A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text(
                      "Verify",
                      style: TextStyle(color: Colors.white, fontFamily: AppConstants.commonFont),
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

