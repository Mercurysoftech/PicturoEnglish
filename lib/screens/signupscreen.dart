import 'package:flutter/material.dart';
import 'package:picturo_app/screens/loginscreen.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../utils/common_file.dart';

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  _SignupscreenState createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool buttonLoading = false;
  bool isOtpSent = false;
  bool isOtpVerified = false;
  int _remainingTime = 60;
  Timer? _timer;
  String _lastVerifiedOtp = "";
  String _verifiedPhoneNumber = ""; // Store the phone number for which OTP was verified

  // Password validation states
  bool _passwordsMatch = true;
  String _passwordValidationMessage = "";
  bool _showPasswordMatchIndicator = false;

  bool _isEmailValid = true;
  String _emailValidationMessage ="";
  bool _showEmailValidationIndicator = false;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Add listeners to OTP controllers to detect changes
    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].addListener(_onOtpChanged);
    }
    // Add listener to phone number controller
    _phoneController.addListener(_onPhoneNumberChanged);
    // Add listeners to password controllers for live validation
    _passwordController.addListener(_validatePasswords);
    _confirmPasswordController.addListener(_validatePasswords);

    _emailController.addListener(_validateEmail);
  }

  void _validatePasswords() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _passwordsMatch = true; // Don't show error when empty
        _passwordValidationMessage = "";
        _showPasswordMatchIndicator = false;
      });
      return;
    }
    
    if (confirmPassword.isNotEmpty) {
      final match = password == confirmPassword;
      setState(() {
        _passwordsMatch = match;
        _passwordValidationMessage = match ? "Passwords match" : "Passwords do not match";
        _showPasswordMatchIndicator = true;
      });
    }
  }

  void _onPhoneNumberChanged() {
    // Reset OTP states if phone number is changed after sending OTP
    String currentPhone = _phoneController.text.trim();
    
    // If OTP was sent or verified, check if phone number changed
    if ((isOtpSent || isOtpVerified) && currentPhone != _verifiedPhoneNumber) {
      setState(() {
        isOtpVerified = false;
        isOtpSent = false;
        _lastVerifiedOtp = "";
        _verifiedPhoneNumber = "";
        _remainingTime = 60;
        _timer?.cancel();
      });
      _clearOtpFields();
    }
  }

  void _onOtpChanged() {
    // Reset verification if OTP is changed after verification
    if (isOtpVerified) {
      String currentOtp = _getCurrentOtp();
      if (currentOtp != _lastVerifiedOtp) {
        setState(() {
          isOtpVerified = false;
          _lastVerifiedOtp = "";
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    // Basic email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      setState(() {
        _isEmailValid = true; // Don't show error when empty
        _emailValidationMessage = "";
        _showEmailValidationIndicator = false;
      });
      return;
    }
    
    if (email.isNotEmpty) {
      final isValid = _isValidEmail(email);
      setState(() {
        _isEmailValid = isValid;
        _emailValidationMessage = isValid ? "Valid email format" : "Invalid email format";
        _showEmailValidationIndicator = true;
      });
    }
  }


  String _getCurrentOtp() {
    String otp = '';
    for (var controller in _otpControllers) {
      otp += controller.text;
    }
    return otp;
  }

  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.removeListener(_onPhoneNumberChanged);
    _passwordController.removeListener(_validatePasswords);
    _confirmPasswordController.removeListener(_validatePasswords);
    _emailController.removeListener(_validateEmail);
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _otpControllers) {
      controller.removeListener(_onOtpChanged);
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _remainingTime = 60;
      isOtpVerified = false;
      _lastVerifiedOtp = "";
    });
    _startTimer();
  }

  bool _validatePhoneNumber() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage("Phone number is required.");
      return false;
    }
    if (phone.length != 10) {
      _showMessage("Phone number must be 10 digits.");
      return false;
    }
    return true;
  }

  bool _validateForm() {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();
    final String phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || phone.isEmpty) {
      _showMessage("All fields are required.");
      return false;
    }

    if (password != confirmPassword) {
      _showMessage("Passwords do not match.");
      return false;
    }

    if (!isOtpVerified) {
      _showMessage("Please verify OTP first.");
      return false;
    }

    // Verify that the current phone number matches the verified phone number
    if (phone != _verifiedPhoneNumber) {
      _showMessage("Please verify OTP for the current phone number.");
      return false;
    }

    return true;
  }

  Future<void> _sendOtp() async {
    if (!_validatePhoneNumber()) return;

    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      _showMessage("Please enter a valid email address before sending OTP.");
      return;
    }

    setState(() {
      buttonLoading = true;
    });

    final apiService = await ApiService.create();
    bool otpSent = await apiService.hitForOTP(_phoneController.text.trim());

    setState(() {
      buttonLoading = false;
    });

    if (otpSent) {
      _showMessage("OTP sent successfully!");
      setState(() {
        isOtpSent = true;
        isOtpVerified = false;
        _lastVerifiedOtp = "";
        _verifiedPhoneNumber = _phoneController.text.trim(); // Store phone number when OTP is sent
      });
      _clearOtpFields();
      _resetTimer();
    } else {
      _showMessage("Failed to send OTP. Please try again.");
    }
  }

  Future<void> _verifyOtp() async {
    String currentOtp = _getCurrentOtp();

    if (currentOtp.length != 4) {
      _showMessage("Please enter 4-digit OTP.");
      return;
    }

    setState(() {
      buttonLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    String? storedOtp = prefs.getString('otp_verify');

    if (storedOtp != null && storedOtp == currentOtp) {
      _showMessage("OTP verified successfully!");
      setState(() {
        isOtpVerified = true;
        _lastVerifiedOtp = currentOtp;
        // _verifiedPhoneNumber is already set when OTP was sent, no need to update here
        buttonLoading = false;
      });
    } else {
      _showMessage("Invalid OTP. Please try again.");
      setState(() {
        buttonLoading = false;
      });
    }
  }

  Future<void> _handleSignup() async {
    if (!_validateForm()) return;

    setState(() {
      buttonLoading = true;
    });

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String phone = _phoneController.text.trim();

    final apiService = await ApiService.create();
    final result = await apiService.signup(name, email, phone, password, context);

    if (result["success"] == true) {
      final String? token = result["token"];
      final String? userId = result["user_id"];

      if (token != null && userId != null) {
        _showMessage("Registration successful!");
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);
        await prefs.setString("user_id", userId);

        await prefs.remove('otp_verify');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        _showMessage("Invalid response from server. Please try again.");
      }
    } else {
      _showMessage(result["error"] ?? "Signup failed. Please try again.");
    }

    setState(() {
      buttonLoading = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  Widget _buildOtpField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter OTP",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: AppConstants.commonFont,
          ),
        ),
        SizedBox(height: 10),
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
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: AppConstants.commonFont,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isOtpVerified ? Colors.green : Color(0xFF49329A),
                      width: isOtpVerified ? 2 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isOtpVerified ? Colors.green : Color(0xFF49329A),
                      width: isOtpVerified ? 2 : 1,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.length == 1 && index < 3) {
                    FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
                  } else if (value.isEmpty && index > 0) {
                    FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
                  }
                  
                  if (index == 3 && value.isNotEmpty) {
                    String currentOtp = _getCurrentOtp();
                    if (currentOtp.length == 4 && !isOtpVerified) {
                      _verifyOtp();
                    }
                  }
                },
              ),
            );
          }),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _remainingTime == 0 ? _sendOtp : null,
              child: Text(
                'Resend OTP',
                style: TextStyle(
                  color: _remainingTime == 0 ? Color(0xFF49329A) : Colors.grey,
                  fontFamily: AppConstants.commonFont,
                ),
              ),
            ),
            Text(
              '${_remainingTime ~/ 60}:${_remainingTime % 60 < 10 ? '0' : ''}${_remainingTime % 60}',
              style: TextStyle(
                color: Colors.black54,
                fontFamily: AppConstants.commonFont,
              ),
            ),
          ],
        ),
        if (isOtpVerified)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 5),
                Text(
                  "OTP Verified",
                  style: TextStyle(
                    color: Colors.green,
                    fontFamily: AppConstants.commonFont,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 20),
      ],
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
                    SizedBox(height: screenHeight * 0.04),
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
                         Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              // Email validation indicator
                              if (_showEmailValidationIndicator)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isEmailValid ? Icons.check_circle : Icons.error,
                                        color: _isEmailValid ? Colors.green : Colors.red,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        _emailValidationMessage,
                                        style: TextStyle(
                                          color: _isEmailValid ? Colors.green : Colors.red,
                                          fontSize: 12,
                                          fontFamily: AppConstants.commonFont,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
                         Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              // Password match indicator
                              if (_showPasswordMatchIndicator)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _passwordsMatch ? Icons.check_circle : Icons.error,
                                        color: _passwordsMatch ? Colors.green : Colors.red,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        _passwordValidationMessage,
                                        style: TextStyle(
                                          color: _passwordsMatch ? Colors.green : Colors.red,
                                          fontSize: 12,
                                          fontFamily: AppConstants.commonFont,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 15),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
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
                              SizedBox(width: 5),
                              Expanded(
                                child: _buildTextField(
                                  maxLength: 10,
                                  textInputType: TextInputType.phone,
                                  controller: _phoneController,
                                  hintText: "Phone Number",
                                  fontStyle: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Poppins Regular',
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: isOtpSent ? null : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF49329A),
                                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: buttonLoading && !isOtpSent
                                    ? SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 0.7,
                                        ),
                                      )
                                    : Text(
                                        isOtpSent && _remainingTime > 0 ? 'Sent' : 'Send OTP',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontFamily: AppConstants.commonFont,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          if (isOtpSent) _buildOtpField(),
                          SizedBox(height: 20),
                          Center(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (buttonLoading || !isOtpVerified) ? null : _handleSignup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isOtpVerified ? Color(0xFF49329A) : Colors.grey,
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: buttonLoading
                                    ? SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 0.7,
                                        ),
                                      )
                                    : Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: AppConstants.commonFont,
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
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: "Already have an account? ",
                                  style: TextStyle(color: Colors.grey, fontFamily: AppConstants.commonFont, fontSize: 15),
                                  children: [
                                    TextSpan(
                                      text: "Sign In",
                                      style: TextStyle(
                                        color: Color(0xFF49329A),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: AppConstants.commonFont,
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
    TextInputType? textInputType,
    int? maxLength,
    bool obscureText = false,
    TextStyle? fontStyle,
  }) {
    return TextField(
      keyboardType: textInputType,
      maxLength: maxLength,
      controller: controller,
      obscureText: obscureText,
      style: fontStyle,
      buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) {
        return SizedBox.shrink();
      },
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