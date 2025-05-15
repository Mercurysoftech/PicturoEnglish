import 'package:flutter/material.dart';
import 'package:picturo_app/screens/loginscreen.dart';
import 'package:picturo_app/services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  final String? emailId;
  const ChangePasswordPage({super.key, this.emailId});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  late ApiService apiService;

  Future<void> initializeApiService() async {
    apiService = await ApiService.create();
  }

  @override
  void initState() {
    super.initState();
    initializeApiService();
  }

  Future<void> _changePassword() async {
    setState(() {
      _isLoading = true;
    });

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate input fields
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage("Please fill in all fields");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage("Passwords do not match");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (newPassword.length < 6) {
      _showMessage("Password must be at least 6 characters");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await apiService.changePasswordCode(
        widget.emailId ?? '',
        newPassword,
        context,
      );

      print(response);

      if (response["status"] == "success") {
        _showMessage(response["message"] ?? "Password changed successfully");
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
      } else {
        _showMessage(response["error"] ?? "Failed to change password");
      }
    } catch (e) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        centerTitle: true,
        title: const Text(
          'Change password',
          style: TextStyle(
            fontFamily: 'Poppins Regular',
            color: Color(0xFF49329A),
            fontWeight: FontWeight.bold,
          ),
        ),
        toolbarHeight: 100,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF49329A), width: 1.2),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    top: 5,
                    bottom: 5,
                    right: 10,
                  ),
                  child: Image.asset(
                    'assets/solar_lock-linear.png',
                    width: 22,
                    height: 22,
                  ),
                ),
                hintText: "New password",
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins Regular',
                  color: Color(0xFF464646),
                  fontSize: 15,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF49329A), width: 1.2),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    top: 5,
                    bottom: 5,
                    right: 10,
                  ),
                  child: Image.asset(
                    'assets/solar_lock-linear.png',
                    width: 22,
                    height: 22,
                  ),
                ),
                hintText: "Confirm password",
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins Regular',
                  color: Color(0xFF464646),
                  fontSize: 15,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF49329A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Change",
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 17,
                          fontFamily: 'Poppins Regular',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}