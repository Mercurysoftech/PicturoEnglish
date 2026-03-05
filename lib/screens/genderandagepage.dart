import 'package:flutter/material.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picturo_app/screens/languageselectionpage.dart';

import '../utils/common_file.dart';

class GenderAgeScreen extends StatefulWidget {
  const GenderAgeScreen({super.key});

  @override
  _GenderAgeScreenState createState() => _GenderAgeScreenState();
}

class _GenderAgeScreenState extends State<GenderAgeScreen> {
  bool _isMaleSelected = true; // true = Male, false = Female
  String? selectedLevel;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  DateTime? lastPressed;
  final List<String> qualifications = ["PHD", "PG", "UG", "HSC", "SSLC", "Others"];
  String? selectedQualification;

  Future<bool> onWillPop() async {
    DateTime now = DateTime.now();
    if (lastPressed == null || now.difference(lastPressed!) > Duration(seconds: 2)) {
      lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Press back again to exit')),
      );
      return false;
    }
    return true;
  }

  // Function to save gender & age in SharedPreferences (save empty if not filled)
  Future<void> _saveGenderAge({bool skip = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // If skip is true or fields are empty, save empty values
    await prefs.setString("gender", skip ? "" : (_isMaleSelected ? "Male" : "Female"));
    await prefs.setString("age", skip ? "" : _ageController.text.trim());
    await prefs.setString("qualification", skip ? "" : (selectedQualification ?? ""));
    await prefs.setString("language_level", skip ? "" : (selectedLevel ?? ""));
    await prefs.setString("purpose", skip ? "" : _purposeController.text.trim());

    print("Saved: Gender = ${skip ? "Empty" : (_isMaleSelected ? "Male" : "Female")}, Age = ${skip ? "Empty" : _ageController.text}");
    print("Qualification = ${skip ? "Empty" : (selectedQualification ?? "")}");
    print("Language Level = ${skip ? "Empty" : (selectedLevel ?? "")}");
    print("Purpose = ${skip ? "Empty" : _purposeController.text.trim()}");
  }

  bool _isFormValid() {
    return _ageController.text.isNotEmpty &&
           selectedQualification != null &&
           selectedLevel != null &&
           _purposeController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await onWillPop();
          if (shouldPop) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Basic Details',
                          style: TextStyle(
                            fontFamily: AppConstants.commonFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF231065),
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      const Text(
                        "Age",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppConstants.commonFont,
                          color: Color(0xFF231065)
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Age TextField
                      TextField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          hintText: "Eg: 16",
                          hintStyle: const TextStyle(
                            fontFamily: AppConstants.commonFont,
                            color: Color(0xFF9B9B9B),
                          ),
                          
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 1.5),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontFamily: AppConstants.commonFont),
                        onChanged: (_) => setState(() {}), // Trigger rebuild for button state
                      ),
                      SizedBox(height: 25),
                      Text(
                        "Qualification",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,fontFamily: AppConstants.commonFont,color: Color(0xFF231065)),
                      ),
                      SizedBox(height: 10),
                      // Dropdown for Qualification
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: selectedQualification,
                        decoration: InputDecoration(
                          hintText: "Select qualification",
                          hintStyle: const TextStyle(
                            fontFamily: AppConstants.commonFont,
                            color: Color(0xFF9B9B9B),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: qualifications.map((String qualification) {
                          return DropdownMenuItem<String>(
                            value: qualification,
                            child: Text(
                              qualification,
                              style: TextStyle(
                                fontFamily: AppConstants.commonFont,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedQualification = value;
                          });
                        },
                      ),
                      SizedBox(height: 25),
                      Text(
                        "Your Language Proficiency",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,fontFamily: AppConstants.commonFont,color: Color(0xFF231065)),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: selectedLevel,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12,vertical: 15),
                        ),
                        items: ["Beginner", "Intermediate", "Proficient"].map((String level) {
                          return DropdownMenuItem<String>(
                            value: level,
                            child: Text(level,style:TextStyle(fontFamily: AppConstants.commonFont,fontWeight: FontWeight.bold),),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedLevel = value;
                          });
                        },
                      ),
                      SizedBox(height: 25),
                      Text(
                        "Purpose of Learning",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,fontFamily: AppConstants.commonFont,color: Color(0xFF231065)),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _purposeController,
                        decoration: InputDecoration(
                          hintText: "eg. to learn",
                          hintStyle: const TextStyle(
                            fontFamily: AppConstants.commonFont,
                            color: Color(0xFF9B9B9B),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFC3C3C3), width: 1.5),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        style: const TextStyle(fontFamily: AppConstants.commonFont),
                        onChanged: (_) => setState(() {}), // Trigger rebuild for button state
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Gender",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: AppConstants.commonFont,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF231065),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: screenWidth * 0.9,
                          child: AnimatedToggleSwitch<bool>.size(
                            current: _isMaleSelected,
                            values: const [false, true],
                            indicatorSize: const Size.fromWidth(200),

                            iconOpacity: 0.2,
                            customIconBuilder: (context, local, global) {
                              return Text(
                                local.value ? 'Male' : 'Female',
                                style: TextStyle(
                                  color: Color.lerp(Colors.black, Colors.white, local.animationValue),
                                  fontFamily: AppConstants.commonFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              );
                            },
                            iconAnimationType: AnimationType.onHover,
                            style: ToggleStyle(
                              indicatorColor: const Color(0xFF49329A),
                              borderColor: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              backgroundColor: const Color(0xFFF2F2F2),
                            ),
                            selectedIconScale: 1.0,
                            onChanged: (value) {
                              setState(() {
                                _isMaleSelected = value;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      
                      // Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Skip Button
                          SizedBox(
                            width: screenWidth * 0.35,
                            child: OutlinedButton(
                              onPressed: () async {
                                await _saveGenderAge(skip: true);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => LanguageSelectionApp()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                 textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                 side: const BorderSide(
                                  color: Color(0xFF49329A),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                child: Text(
                                  "Skip",
                                  style: TextStyle(
                                    color: const Color(0xFF49329A),
                                    fontSize: 18,
                                    fontFamily: AppConstants.commonFont,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          
                          // Continue Button (disabled until all fields are filled)
                          SizedBox(
                            width: screenWidth * 0.35,
                            child: ElevatedButton(
                              onPressed: _isFormValid() ? () async {
                                await _saveGenderAge(skip: false);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => LanguageSelectionApp()),
                                );
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFormValid() ? Color(0xFF49329A) : Colors.grey[400],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 15),
                                child: Text(
                                  "Continue",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily: AppConstants.commonFont,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}