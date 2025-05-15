import 'package:flutter/material.dart';
import 'package:picturo_app/screens/genderandagepage.dart';
import 'package:picturo_app/screens/loginscreen.dart';
import 'package:picturo_app/screens/verificationscreen.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import your ApiService

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  _SignupscreenState createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool buttonLoading=false;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Function to handle signup
  Future<void> _handleSignup() async {
    // Get input values
    setState(() {
      buttonLoading=true;
    });
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();
    final String phone = _phoneController.text.trim();

    // Validate input
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || phone.isEmpty) {
      _showMessage("All fields are required.");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Passwords do not match.");
      return;
    }

    // Call the signup API
    final apiService = await ApiService.create();
    final result = await apiService.signup(name, email, phone, password, context);



    if (result["success"] == true) {
      bool otpSend = await apiService.hitForOTP(phone);
      if(otpSend){
        final String? token = result["token"];
        final String? userId = result["user_id"]; // Use "userid" (lowercase) to match the API response
        // Navigate to VerificationScreen on success
        if (token != null && userId != null) {
          _showMessage("Register successful!");

          // Save token and userId to SharedPreferences (if not already done in ApiService)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("auth_token", token);
          await prefs.setString("user_id", userId);
          print('Token: $token');
          print('UserId:$userId');

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VerificationScreen(mailId:email ,mobile:phone ,)),
          );
          //       Navigator.pushAndRemoveUntil(
          //   context,
          //   MaterialPageRoute(builder: (context) => GenderAgeScreen()),
          //   (route) => false,
          // );
        } else {
          _showMessage("Invalid response from server. Please try again.");
        }
        setState(() {
          buttonLoading=false;
        });
      }

    } else {
      // Show error message
      _showMessage(result["error"] ?? "Signup failed. Please try again.");
    }
  }

   void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEEFFF), Color(0xFFFFF0D3), Color(0xFFE7F8FF), Color(0xFFEEEFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.07),
                    Container(
                      width: screenWidth,
                      height: screenHeight * 0.17,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/Illustration.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Create an Account",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins Regular',
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Sign Up to continue",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins Regular',
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          _buildTextField(
                            controller: _nameController,
                            hintText: "Name",
                            fontStyle: TextStyle(fontFamily: 'Poppins Regular'),
                            icon: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Image.asset(
                                'assets/iconamoon_profile-thin.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          _buildTextField(
                            controller: _emailController,
                            hintText: "Email ID",
                            fontStyle: TextStyle(fontFamily: 'Poppins Regular'),
                            icon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset(
                                'assets/Vector.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          _buildPasswordField(
                            controller: _passwordController,
                            hintText: "Password",
                            icon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset(
                                'assets/solar_lock-linear.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                            isVisible: isPasswordVisible,
                            onToggle: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          SizedBox(height: 15),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            hintText: "Confirm Password",
                            icon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset(
                                'assets/solar_lock-linear.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                            isVisible: isConfirmPasswordVisible,
                            onToggle: () {
                              setState(() {
                                isConfirmPasswordVisible = !isConfirmPasswordVisible;
                              });
                            },
                          ),
                          SizedBox(height: 15),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButton<String>(
                                  underline: SizedBox(),
                                  value: "+91",
                                  style: TextStyle(
                                    fontFamily: 'Poppins Regular',
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: "+91",
                                      child: Text("+91"),
                                    ),
                                  ],
                                  onChanged: (value) {},
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _buildTextField(
                                  controller: _phoneController,
                                  hintText: "Phone Number",
                                  fontStyle: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Poppins Regular',
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 45),
                          Center(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleSignup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF49329A),
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: (buttonLoading)?SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 0.7,
                                  ),
                                ):Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Poppins Medium',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                 Navigator.pushNamed(context, '/login');
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: "Already have an account? ",
                                  style: TextStyle(color: Colors.grey, fontFamily: 'Poppins Medium', fontSize: 15),
                                  children: [
                                    TextSpan(
                                      text: "Sign In",
                                      style: TextStyle(
                                        color: Color(0xFF49329A),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins Medium',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    Widget? icon,
    bool obscureText = false,
    TextStyle? fontStyle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: fontStyle,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: icon,
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Color(0xFF737373)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFC3C3C3), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFC3C3C3), width: 0.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required Widget icon,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: icon,
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Color(0xFF49329A),
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Color(0xFF737373)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFC3C3C3), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFC3C3C3), width: 0.5),
        ),
      ),
    );
  }
}