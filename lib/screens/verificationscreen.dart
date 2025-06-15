import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:picturo_app/screens/changepasswordpage.dart';
import 'dart:async';

import 'package:picturo_app/screens/successfullyverification.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/common_file.dart';
import 'genderandagepage.dart'; // For the Timer

class VerificationScreen extends StatefulWidget {
  final String? mobile;
  final String? mailId;
  final bool? isForgotOTP;
  const VerificationScreen({super.key, this.mobile, this.mailId,this.isForgotOTP});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  int _remainingTime = 60; // Start with 1 minute
  late Timer _timer;
  late ApiService apiService;
  bool _isLoading = false; 
  // Add these controllers to your state class
final List<TextEditingController> _otpControllers = List.generate(4, (index) => TextEditingController());
final List<FocusNode> _otpFocusNodes = List.generate(4, (index) => FocusNode());


  // Method to initialize ApiService
  Future<void> initializeApiService() async {
    apiService = await ApiService.create(); // Using the static create method
  }

  Future<void> verifyCode({
    required String email,
    required String code,
  }) async {
    final url = Uri.parse('http://picturoenglish.com/api/verify_code.php');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('auth_token'); // Make sure this is already saved

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'email': email,
      'code': code,
    });

    try {

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Success: $responseData');

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>ChangePasswordPage(emailId: widget.mailId,)));
      } else {
        print('❌ Failed: ${response.statusCode}');
        Fluttertoast.showToast(msg: "Otp Mismatched",backgroundColor: Colors.red);

      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Something Went Wrong ! Otp Mismatched",backgroundColor: Colors.red);

    }
  }


  Future<void> _verifyOTP() async {
    print("s;dc;sld,cdsc");
  setState(() {
    _isLoading = true;
  });
  String otp = '';
  for (var controller in _otpControllers) {
    otp += controller.text;
  }
  if(widget.isForgotOTP!=null){
    await verifyCode(email: widget.mailId??'',code: otp);
  }else{
    final prefs = await SharedPreferences.getInstance();
    String? otpSended= prefs.getString('otp_verify');

    if(otpSended!=null){
      if(otpSended==otp){
        Fluttertoast.showToast(msg: "Otp Verified",backgroundColor: Colors.green);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GenderAgeScreen()),
        );
      }else{
        Fluttertoast.showToast(msg: "Otp Mismatched",backgroundColor: Colors.red);
      }
    }

  }
  setState(() {
    _isLoading = false;
  });
  // Combine all OTP digits into one string

}

void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
    initializeApiService();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  void _resendOtp() async{
    final apiService = await ApiService.create();
    bool otpSend = await apiService.hitForOTP(widget.mobile??'');
    if(otpSend){
      setState(() {
        _remainingTime = 60;
      });
      _startTimer();
    }

  }

  @override
  void dispose() {
     _timer.cancel();
  for (var controller in _otpControllers) {
    controller.dispose();
  }
  for (var focusNode in _otpFocusNodes) {
    focusNode.dispose();
  }
  super.dispose();
  }


  String maskMobile(String mobile) {
    if (mobile.length >= 3) {
      return '*********${mobile.substring(mobile.length - 3)}';
    }
    return mobile; 
  }

  
  String maskEmail(String email) {
    int atIndex = email.indexOf('@');
    if (atIndex > 1) {
      return '${email[0]}***${email.substring(atIndex)}';
    }
    return email; 
  }

  @override
  Widget build(BuildContext context) {
    String displayText = "";
    
    if (widget.mobile != null && widget.mobile!.isNotEmpty) {
      displayText = "We sent you an SMS to your mobile ${maskMobile(widget.mobile!)}";
    } else if (widget.mailId != null && widget.mailId!.isNotEmpty) {
      displayText = "We sent you an OTP to your email ${maskEmail(widget.mailId!)}";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
        centerTitle: true,
        toolbarHeight: 50,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Verify Number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF231065),
                fontFamily: AppConstants.commonFont,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontFamily: AppConstants.commonFont,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 50,
                  height: 50,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.normal, fontFamily: AppConstants.commonFont),
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF49329A), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF49329A), width: 2),
                      ),
                    ),
                     onChanged: (value) {
          if (value.length == 1 && index < 3) {
            FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
          }
        },
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: (_isLoading)?(){}: _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF49329A),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: (_isLoading)?SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 0.8,color: Colors.white,),
              ):const Text(
                'Verify',
                style: TextStyle(
                    fontSize: 18, color: Colors.white, fontFamily: AppConstants.commonFont, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _remainingTime == 0 ? _resendOtp : null,
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: _remainingTime == 0 ? Color(0xFF49329A) : Colors.black54,
                      fontFamily: AppConstants.commonFont,
                    ),
                  ),
                ),
                Text(
                  'Estimated time ${_remainingTime ~/ 60}:${_remainingTime % 60 < 10 ? '0' : ''}${_remainingTime % 60}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontFamily: AppConstants.commonFont,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
}
