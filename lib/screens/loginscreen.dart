import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:picturo_app/providers/userprovider.dart';
import 'package:picturo_app/screens/forgotpasswordpage.dart';
import 'package:picturo_app/screens/genderandagepage.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/screens/languageselectionpage.dart';
import 'package:picturo_app/screens/locationgetpage.dart';
import 'package:picturo_app/screens/signupscreen.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/common_file.dart';
import 'helperbotpage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isChecked = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    initializeApiService();
    _loadSavedCredentials();
  }

   // Load saved credentials if they exist
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    
    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _isChecked = true;
      });
    }
  }

  // Save credentials to shared preferences
  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
  }

  // Clear saved credentials
  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }


  Future<void> initializeApiService() async {
    apiService = await ApiService.create();
  }

  Future<void> _login() async {
    print("inside login");
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please fill in all fields.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await apiService.login(email, password, context);

      if (response["success"] == true) {
         if (_isChecked) {
          await _saveCredentials(email, password);
        } else {
          await _clearCredentials();
        }
        
        final String? token = response["token"];
        final String? userId = response["userid"];
        

        if (token != null && userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("auth_token", token);
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString("user_id", userId);

          Provider.of<UserProvider>(context, listen: false).setUserId(userId);

          final profileResponse = await apiService.fetchProfileDetails();


          if (profileResponse.age == 0 ||
              profileResponse.gender.isEmpty ||
              profileResponse.qualification.isEmpty ||
              profileResponse.speakingLevel.isEmpty ||
              profileResponse.reason.isEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GenderAgeScreen()),
            );
          } else if (profileResponse.speakingLanguage.isEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LanguageSelectionApp()),
            );
          } else if (profileResponse.location.isEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LocationGetPage(isFromProfile: false,)),
            );
          } else {
            _showMessage("Login successful!");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Homepage()),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          _showMessage("Invalid response from server. Please try again.");

        }
      } else {
        setState(() {
          _isLoading = false;
        });

        if(response['error'].toString().contains("User already logged in on another device.")){
          _showMessage("User already logged in on another device.");
        }else{
          _showMessage(response["error"] ?? "Login failed. Please try again.");
        }


      }


    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage("An error occurred. Please try again.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
                      height: screenHeight * 0.23,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/login_illustration.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            "Welcome back",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppConstants.commonFont,
                              color: Color(0xFF231065),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Sign In to continue",
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: AppConstants.commonFont,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: "Email",
                              hintStyle: const TextStyle(color: Color(0xFF737373)),
                              prefixIcon: IconButton(
                                icon: Image.asset(
                                  'assets/Vector.png',
                                  height: 22,
                                  width: 22,
                                ),
                                onPressed: () {},
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: InputBorder.none,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 0.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 0.5),
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Poppins Regular',
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: "Password",
                              hintStyle: const TextStyle(color: Color(0xFF737373)),
                              prefixIcon: IconButton(
                                icon: Image.asset(
                                  'assets/solar_lock-linear.png',
                                  height: 22,
                                  width: 22,
                                ),
                                onPressed: () {},
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: const Color(0xFF737373),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 0.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 0.5),
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Poppins Regular',
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _isChecked,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        _isChecked = newValue ?? false;
                                      });
                                    },
                                    side: BorderSide(
                                      color: _isChecked ? const Color(0xFF4CAF50) : Colors.grey,
                                      width: _isChecked ? 2.0 : 0.0,
                                    ),
                                    activeColor: const Color(0xFF4CAF50),
                                    fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return const Color(0xFF4CAF50);
                                      }
                                      return Colors.white;
                                    }),
                                  ),
                                  const Text(
                                    "Remember me",
                                    style: TextStyle(
                                      fontFamily: 'Poppins Regular',
                                      fontSize: 13,
                                      color: Color(0xFF494949),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                  );
                                },
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    fontFamily: 'Poppins Regular',
                                    fontSize: 13,
                                    color: Color(0xFF737373),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: !_isLoading ? _login : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF49329A),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  :  Text(
                                      "Sign In",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: AppConstants.commonFont,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: "Don’t have an account? ",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontFamily: AppConstants.commonFont,
                                  fontSize: 15,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Sign Up",
                                    style:  TextStyle(
                                      color: Color(0xFF49329A),
                                      fontFamily: AppConstants.commonFont,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                     Navigator.push(context, MaterialPageRoute(builder: (context)=>Signupscreen()));
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20,),
                          InkWell(
                            onTap: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => HelperBotScreen()), // Navigate to BlockedUsersPage
                              );
                            },
                            child: Center(
                              child: RichText(
                                text: TextSpan(
                                  text: "Do You Need Help ? ",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontFamily: AppConstants.commonFont,
                                    fontSize: 15,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Click Here",
                                      style:  TextStyle(
                                        color: Colors.orange,
                                        fontFamily: AppConstants.commonFont,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => HelperBotScreen()), // Navigate to BlockedUsersPage
                                          );
                                        },
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
}
