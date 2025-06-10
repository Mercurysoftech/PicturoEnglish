import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:picturo_app/responses/language_response.dart';
import 'package:picturo_app/screens/locationgetpage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../responses/my_profile_response.dart';
import '../utils/common_file.dart';

class ChangeLanguagePage extends StatefulWidget {
  const ChangeLanguagePage({super.key});

  @override
  State<ChangeLanguagePage> createState() => _ChangeLanguagePageState();
}

class _ChangeLanguagePageState extends State<ChangeLanguagePage> {
  String? selectedLanguage;
  final double _scale = 1.0;  // This controls the scaling effect
  List<LanguageData> languages = []; // Store fetched languages
  UserResponse? userResponse;
  bool loading=false;
  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    fetchAndDisplayLanguages(); // Fetch languages on screen load
  }
  Future<void> fetchUserDetails() async {
    try {
      final apiService = await ApiService.create();
      final response = await apiService.fetchProfileDetails();

      setState(() {
        userResponse=response;
        selectedLanguage=userResponse?.speakingLanguage??'';
      });
    } catch (e) {
      setState(() {

      });
      print("Error fetching questions: $e");
    }
  }

   Future<void> fetchAndDisplayLanguages() async {
    try {
      final apiService = await ApiService.create();
      final LanguageResponse languageResponse = await apiService.fetchLanguages();

      // Filter the languages where country_id is 97
      final filteredLanguages = languageResponse.data.where((language) => language.countryId == 97 &&  ["Tamil", "Telugu", "Hindi", "Malayalam", "English"].contains(language.language)).toList();

      setState(() {
        languages = filteredLanguages; // Update the state with filtered languages
      });
    } catch (e) {
      print("Error fetching languages: $e");
    }
  }

  void _showLanguageBottomSheet() {
    if(languages.isNotEmpty) {
      showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Select a Language",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: AppConstants.commonFont,
                color: Color(0xFF522B8F),
              ),
            ),
            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: languages.map((language) {
                bool isSelected = selectedLanguage == language.language;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: GestureDetector(
                    onTap: () async {

                      setState(() {
                        selectedLanguage = language.language;
                      });
                      Navigator.pop(context);

                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF49329A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF49329A), width: 1),
                      ),
                      child: Text(
                        language.language,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppConstants.commonFont,
                          color: isSelected ? Colors.white : const Color(0xFF49329A),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      );
    },
  );
    }
}






  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // Increased app bar height
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0), // Adjust top padding
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0), // Adjust top padding
            child: Row(
              children: [
                Text(
                  'Change Language',
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Text(
              "Choose your preferred language to personalize your learning experience. This will help us with translations and explanations to make learning English easier and more effective for you!",
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 13, color: Colors.grey[700], fontFamily: 'Poppins Regular'),
            ),
          ),

          const SizedBox(height: 20),
          // Language Selection Tiles
          languageSelectionTile("You're Learning ", "English"),
          const SizedBox(height: 20),
          const Icon(Icons.arrow_downward, color: Color(0xFF49329A), size: 30),
          const SizedBox(height: 15),


          // You're Learning - TextField with Bottom Sheet
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Positioned label similar to languageSelectionTile
              const SizedBox(height: 5),
              GestureDetector(
                onTap:_showLanguageBottomSheet,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Border Box for TextField
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF49329A), width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        textAlign: TextAlign.center,
                        selectedLanguage ?? "Select a language",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppConstants.commonFont,
                          color: selectedLanguage != null ? Color(0xFF49329A) : Colors.grey,
                        ),
                      ),
                    ),
                    // Positioned label inside the text field
                    Positioned(
                      left: 12,
                      top: -10, // Adjusted for perfect alignment
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        color: Colors.white,
                        child: const Text(
                          "Native Language",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins Regular',
                            color: Color(0xFF49329A),
                            backgroundColor: Colors.white, // Ensures clarity
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
          const Spacer(),

          // Done Button
          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  child: ElevatedButton(
    onPressed: (loading)?(){}:() async{

      if(selectedLanguage!=null){
        setState(() {
          loading=true;
        });
        final apiService = await ApiService.create();
        final bool languageResponse = await apiService.setUserNativeLanguage(selectedLanguage??'');
        print("sdlkslkdcmsc ${languageResponse}");
        if(languageResponse){

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('selectedLanguage', selectedLanguage??'');
          Navigator.pop(context);
        }
        setState(() {
          loading=false;
        });
      }else{
        Fluttertoast.showToast(msg: "Please Choose any Languages");
      }


    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF49329A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      minimumSize: const Size(double.infinity, 55),
      elevation: 5, // Default elevation
      splashFactory: InkRipple.splashFactory, // Enable ripple effect
      // Adjust elevation when the button is pressed for a 'pressed' effect
      shadowColor: Colors.purple.withOpacity(0.5),
    ),
    child: (loading)?SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(
        strokeWidth: 0.8,
      ),
    ):const Text(
      "Done",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: AppConstants.commonFont,
        color: Colors.white,
      ),
    ),
  ),
)
        ],
      ),
    );
  }

Widget languageSelectionTile(String title, String language) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none, // Allows text to be placed outside the box
        children: [
          // Border Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFF7E65D6), width: 1),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Text(        
              language,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: AppConstants.commonFont,
                color: Color(0xFF7E65D6),
              ),
            ),
          ),

          // Properly Aligned Floating Label
          Positioned(
            left: 12,
            top: -10, // Adjusted for perfect alignment
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              color: Colors.white, // Covers the border
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins Regular',
                  color: Color(0xFF7E65D6),
                  backgroundColor: Colors.white, // Ensures clarity
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
