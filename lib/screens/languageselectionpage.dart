import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picturo_app/responses/language_response.dart';
import 'package:picturo_app/screens/locationgetpage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/common_file.dart';

class LanguageSelectionApp extends StatefulWidget {
  const LanguageSelectionApp({super.key});

  @override
  _LanguageSelectionAppState createState() => _LanguageSelectionAppState();
}

class _LanguageSelectionAppState extends State<LanguageSelectionApp> {
  String? selectedLanguage;
  final double _scale = 1.0; 
  List<LanguageData> languages = [];
  bool _isLoading = false; // Track loading state

  @override
  void initState() {
    super.initState();
    fetchAndDisplayLanguages(); 
  }

  Future<void> fetchAndDisplayLanguages() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final apiService = await ApiService.create();
      final LanguageResponse languageResponse =
          await apiService.fetchLanguages();

      // Filter the languages where country_id is 97
      final filteredLanguages = languageResponse.data
          .where((language) =>
              language.countryId == 97 &&
              ["Tamil", "Telugu", "Hindi", "Malayalam", "English"]
                  .contains(language.language))
          .toList();

      setState(() {
        languages = filteredLanguages;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching languages: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLanguageBottomSheet() {
    if (languages.isNotEmpty) {
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setString(
                              'selectedLanguage', language.language);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF49329A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF49329A), width: 1),
                          ),
                          child: Text(
                            language.language,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppConstants.commonFont,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF49329A),
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
    } else if (_isLoading) {
      // Show loading indicator if languages are still loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Loading languages..."),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Show error if languages couldn't be loaded
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load languages. Please try again."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleDone() async {
    if (selectedLanguage == null) {
      // Show error message if no language is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a native language first."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    String selectedNativeLanguage = selectedLanguage!.toLowerCase();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', selectedNativeLanguage);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LocationGetPage(
          isFromProfile: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return; // If already popped, do nothing
        final shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if (shouldExit ?? false) {
          SystemNavigator.pop(); // Close the app if "Yes" is pressed
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Purple Container with Image and Text
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                      top: 50, left: 20, right: 20, bottom: 150),
                  decoration: const BoxDecoration(
                    color: Color(0xFF49329A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          "Select your",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppConstants.commonFont,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Language  ",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppConstants.commonFont,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 40,
                  child: Image.asset(
                    'assets/select_language.png',
                    height: 200,
                  ),
                ),
              ],
            ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                "Choose your preferred language to personalize your learning experience. This will help us with translations and explanations to make learning English easier and more effective for you!",
                textAlign: TextAlign.start,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontFamily: 'Poppins Regular'),
              ),
            ),

            const SizedBox(height: 20),
            // Language Selection Tiles
            languageSelectionTile("You're Learning ", "English"),
            const SizedBox(height: 20),
            const Icon(Icons.arrow_downward,
                color: Color(0xFF49329A), size: 30),
            const SizedBox(height: 15),

            // You're Learning - TextField with Bottom Sheet
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Positioned label similar to languageSelectionTile
                  const SizedBox(height: 5),
                  if (_isLoading && languages.isEmpty)
                    const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 0.8,
                          color: Color(0xFF49329A),
                        ),
                      ),
                    )
                  else if (!_isLoading && languages.isEmpty)
                    GestureDetector(
                      onTap: fetchAndDisplayLanguages,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 15),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.red, width: 1), // Red border for error
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          textAlign: TextAlign.center,
                          "Tap to retry loading languages",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppConstants.commonFont,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _showLanguageBottomSheet,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Border Box for TextField
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 15),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: selectedLanguage == null 
                                      ? const Color(0xFF49329A) 
                                      : Colors.green, // Green border when selected
                                  width: selectedLanguage == null ? 1 : 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    selectedLanguage ?? "Select a language",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: AppConstants.commonFont,
                                      color: selectedLanguage != null
                                          ? const Color(0xFF49329A)
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                if (selectedLanguage != null)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                          // Positioned label inside the text field
                          Positioned(
                            left: 12,
                            top: -10, // Adjusted for perfect alignment
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              color: Colors.white,
                              child: Text(
                                "Native Language",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins Regular',
                                  color: selectedLanguage == null
                                      ? const Color(0xFF49329A)
                                      : Colors.green,
                                  backgroundColor: Colors.white,
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
                onPressed: selectedLanguage == null ? null : _handleDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedLanguage == null
                      ? Colors.grey // Grey when disabled
                      : const Color(0xFF49329A), // Purple when enabled
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 55),
                  elevation: selectedLanguage == null ? 0 : 5, // No elevation when disabled
                  splashFactory: selectedLanguage == null
                      ? NoSplash.splashFactory // No ripple when disabled
                      : InkRipple.splashFactory,
                  shadowColor: selectedLanguage == null
                      ? Colors.transparent
                      : Colors.purple.withOpacity(0.5),
                ),
                child: const Text(
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
              border: Border.all(color: const Color(0xFF7E65D6), width: 1),
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