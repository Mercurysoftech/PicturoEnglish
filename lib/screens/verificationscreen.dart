import 'package:flutter/material.dart';
import 'package:picturo_app/screens/changepasswordpage.dart';
import 'dart:async';

import 'package:picturo_app/screens/successfullyverification.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For the Timer

class VerificationScreen extends StatefulWidget {
  final String? mobile;
  final String? mailId;
  const VerificationScreen({super.key, this.mobile, this.mailId});

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

  Future<void> _verifyOTP() async {
  setState(() {
    _isLoading = true;
  });

  // Combine all OTP digits into one string
  String otp = '';
  for (var controller in _otpControllers) {
    otp += controller.text;
  }

  // Validate OTP length
  if (otp.length != 4) {
    _showMessage("Please enter a complete 4-digit OTP");
    setState(() {
      _isLoading = false;
    });
    return;
  }

  final email = widget.mailId ?? '';

  final prefs = await SharedPreferences.getInstance();
  String? otpSended= prefs.getString('otp_verify');

  // try {
  //   final response = await apiService.verifyVerificationCode(email, otp, context);
  //   print("sdcnslkcmnsldkc ${response}");
  //
  //   if (response["status"] == "success") {
  //     _showMessage(response["message"]);
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => ChangePasswordPage(emailId: widget.mailId!,),
  //       ),
  //     );
  //   } else {
  //     _showMessage(response["error"] ?? "OTP verification failed");
  //   }
  // } catch (e) {
  //   _showMessage("An error occurred. Please try again.");
  // } finally {
  //   setState(() {
  //     _isLoading = false;
  //   });
  // }
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
                fontFamily: 'Poppins Medium',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontFamily: 'Poppins Medium',
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
                        fontSize: 20, fontWeight: FontWeight.normal, fontFamily: 'Poppins Medium'),
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
              onPressed: _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF49329A),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Verify',
                style: TextStyle(
                    fontSize: 18, color: Colors.white, fontFamily: 'Poppins Medium', fontWeight: FontWeight.bold),
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
                      fontFamily: 'Poppins Medium',
                    ),
                  ),
                ),
                Text(
                  'Estimated time ${_remainingTime ~/ 60}:${_remainingTime % 60 < 10 ? '0' : ''}${_remainingTime % 60}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontFamily: 'Poppins Medium',
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
