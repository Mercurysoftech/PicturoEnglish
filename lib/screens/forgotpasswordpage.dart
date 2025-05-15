import 'package:flutter/material.dart';
import 'package:picturo_app/screens/verificationscreen.dart';
import 'package:picturo_app/services/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
   final TextEditingController _emailController = TextEditingController();
   late ApiService apiService;
   bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    // Initialize ApiService asynchronously when the widget is created
    initializeApiService();
  }

  // Method to initialize ApiService
  Future<void> initializeApiService() async {
    apiService = await ApiService.create(); // Using the static create method
  }

  Future<void> _sendOTP() async {
  setState(() {
    _isLoading = true; // Show loading indicator
  });

  final email = _emailController.text.trim();

  // Validate input fields
  if (email.isEmpty) {
    _showMessage("Please enter the email.");
    setState(() {
      _isLoading = false; // Hide loading indicator
    });
    return;
  }


  // try {
    // Call the API service to perform login
  final apiService = await ApiService.create();
    final response = await apiService.sendVerificationCode(email, context);

    if (response["status"] == "success") {
       _showMessage(response["message"]);
       Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(mailId:_emailController.text.trim()), // Replace with your HomePage
            ),
          );
    } else {
      _showMessage(response["error"] ?? "Sent OTP failed. Please try again.");
    }
  // } catch (e) {
  //   _showMessage("An error occurred. Please try again.");
  // } finally {
  //   setState(() {
  //     _isLoading = false; // Hide loading indicator
  //   });
  // }
}

void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Color(0xFFFFFFFF),
        centerTitle: false,
        title: Padding(padding: EdgeInsets.only(left: 24,right: 24),
        child:  Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: const Text('Enter email ID',style: TextStyle(fontFamily: 'Poppins Regular', color: Color(0xFF49329A),fontWeight: FontWeight.bold),textAlign: TextAlign.start,),
            ),
             Align(
              alignment: Alignment.topLeft,
              child: const Text('To change password',style: TextStyle(fontFamily: 'Poppins Regular', color: Color(0xFF49329A),fontWeight: FontWeight.bold,fontSize: 16)),
            ),   
          ],
        )),
        toolbarHeight: 100,
      ),
      body: 
      Column(
        children: [
          SizedBox(height: 30,),
          Padding(
              padding: const EdgeInsets.only(left: 24, right: 24),
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                   enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFFC3C3C3),width: 1)
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF49329A),width: 1.2)
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 5,
                        bottom: 5,
                        right: 10), // Adjust spacing
                    child: Image.asset(
                      'assets/Vector.png',
                      width: 22, // Set width & height
                      height: 22,
                    ),
                  ),
                  hintText: "Email ID",
                  hintStyle: TextStyle(fontFamily: 'Poppins Regular', color: Color(0xFF464646), fontSize: 15),
                ),
              )),
          SizedBox(height: 30),
           Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
         child: SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF49329A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                onPressed: _sendOTP,
                child: Text(
                  "Send OTP",
                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17,fontFamily: 'Poppins Regular',fontWeight: FontWeight.bold),
                ),
              ))
           ),
        ],
      ),
    );
  }
}
