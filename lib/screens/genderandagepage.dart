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
  final List<String> qualifications = ["PHD","PG", "UG", "HSC", "SSLC","Others"];
  String? selectedQualification; // Add this variable to store selected value

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


  // Function to save gender & age in SharedPreferences
  Future<void> _saveGenderAge() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("gender", _isMaleSelected ? "Male" : "Female");
  await prefs.setString("age", _ageController.text.trim());
  await prefs.setString("qualification", selectedQualification ?? "Not selected"); // Updated
  await prefs.setString("language_level", selectedLevel ?? "Not selected");
  await prefs.setString("purpose", _purposeController.text.trim());

  print("Saved: Gender = ${_isMaleSelected ? "Male" : "Female"}, Age = ${_ageController.text}");
  print("Qualification = ${selectedQualification ?? "Not selected"}"); // Updated
  print("Language Level = ${selectedLevel ?? "Not selected"}");
  print("Purpose = ${_purposeController.text.trim()}");
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
                    ),
                    SizedBox(height: 25),
                    Text(
                      "Qualification",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,fontFamily: AppConstants.commonFont,color: Color(0xFF231065)),
                    ),
                    SizedBox(height: 10),
                    // Replace the existing Qualification TextField with this:
                    DropdownButtonFormField<String>(
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
                    // Submit Button
                    Center(
                      child: SizedBox(
                        width: screenWidth * 0.4,
                        child: ElevatedButton(
                          onPressed: _isFormValid() ? () async {
                            await _saveGenderAge();
                            Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LanguageSelectionApp()),
    // (route) => true,
  );
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF49329A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Text(
                              "Submit",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: AppConstants.commonFont,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
