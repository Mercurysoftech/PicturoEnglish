import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/profileprovider.dart';
import '../responses/my_profile_response.dart';
import '../utils/common_app_bar.dart';
import '../utils/common_file.dart';
import 'introduction_animation/introduction_animation_screen.dart';
import 'myprofilepage.dart';

class LocationGetPage extends StatefulWidget {
  const LocationGetPage({super.key, this.user, required this.isFromProfile});
  final User? user;
  final bool isFromProfile;

  @override
  _LocationGetPageState createState() => _LocationGetPageState();
}

class _LocationGetPageState extends State<LocationGetPage> {
  String locationMessage = "Location not found";
  bool isLoading = false;
  String gender = "";
  String age = "";
  String qualification = "";
  String languageLevel = "";
  String purpose = "";
  String location = "";
  String reason = "";
  String selectedLanguage = "";

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    if (!serviceEnabled) {
      bool? userWantsToEnable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Location Required"),
          content: Text("This app needs location access to work properly. Turn on location?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Turn On"),
            ),
          ],
        ),
      );

      if (userWantsToEnable == true) {
        serviceEnabled = await Geolocator.openLocationSettings();
        
        if (!serviceEnabled) {
          setState(() => locationMessage = "Location services still disabled");
          return false;
        }
      } else {
        setState(() => locationMessage = "Location services required");
        return false;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => locationMessage = "Location permission denied");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      bool? openedSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Permission Required"),
          content: Text("Location permissions are permanently denied. Open app settings to enable?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Settings"),
            ),
          ],
        ),
      );

      if (openedSettings == true) {
        await Geolocator.openAppSettings();
      }
      return false;
    }

    return true;
  }

  Future<void> _loadSavedData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      gender = prefs.getString("gender") ?? "";
      age = prefs.getString("age") ?? "";
      qualification = prefs.getString("qualification") ?? "";
      languageLevel = prefs.getString("language_level") ?? "";
      purpose = prefs.getString("purpose") ?? "";
      selectedLanguage = prefs.getString("selectedLanguage") ?? "";
    });

    // Log loaded values for debugging (including empty ones)
    print("=== Loaded Data ===");
    print("Gender: ${gender.isEmpty ? "[Empty]" : gender}");
    print("Age: ${age.isEmpty ? "[Empty]" : age}");
    print("Qualification: ${qualification.isEmpty ? "[Empty]" : qualification}");
    print("Language Level: ${languageLevel.isEmpty ? "[Empty]" : languageLevel}");
    print("Purpose: ${purpose.isEmpty ? "[Empty]" : purpose}");
    print("Selected Language: ${selectedLanguage.isEmpty ? "[Empty]" : selectedLanguage}");
  }

  Future<void> _handlePersonalDetails() async {
    final apiService = await ApiService.create();
    final result = await apiService.setPersonalDetails(
      gender,
      age,
      languageLevel,
      location, 
      purpose,
      selectedLanguage,
      qualification,
      context
    );

    if (result["success"] == true) {
      print('Raw Response: $result');
      context.read<ProfileProvider>().fetchProfile();
      if (widget.isFromProfile) {
        Navigator.pop(context);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyProfileScreen()));
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => IntroductionAnimationScreen(),
          ),
        );
      }
    } else {
      _showMessage(result["error"] ?? "Something went wrong. Please try again.");
      if (widget.isFromProfile) {
        Navigator.pop(context);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
          (route) => false,
        );
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
      locationMessage = "Fetching location...";
    });

    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("Latitude: ${position.latitude}");
      print("Longitude: ${position.longitude}");

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        bool isPlusCode = place.name != null && place.name!.contains(RegExp(r'^[A-Z0-9]+\+\w+'));

        String street = isPlusCode ? "" : place.name ?? "";
        String subLocality = place.subLocality ?? "";
        String locality = place.locality ?? "";
        String administrativeArea = place.administrativeArea ?? "";
        String postalCode = place.postalCode ?? "";
        String country = place.country ?? "";

        String address = "$street, $subLocality, $locality, $administrativeArea, $postalCode, $country"
            .replaceAll(RegExp(r'^,|,$'), '') 
            .trim();

        print("Filtered Address: $address");

        setState(() {
          isLoading = false;
          locationMessage = "Location fetched successfully!\n$address";
          location = address; 
        });

      } else {
        setState(() {
          locationMessage = "No address found.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        locationMessage = "Error getting location: ${e.toString()}";
        isLoading = false;
      });

      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      if (widget.user?.location != null) {
        locationMessage = widget.user?.location ?? '';
        location = widget.user?.location ?? '';
      }
    }
    _loadSavedData();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Change Location", isBackbutton: widget.isFromProfile),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.15),
              FractionallySizedBox(
                alignment: Alignment.center,
                widthFactor: 0.8,
                child: Image.asset(
                  'assets/location page.png',
                  height: screenHeight * 0.30,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),

              if (isLoading)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF49329A)),
                )
              else
                Text(
                  locationMessage,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF49329A),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Update My Current Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: AppConstants.commonFont,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 50),
              
              // Buttons Row for Location Page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Skip Button
                  if(!widget.isFromProfile)
                  Expanded(
                    child: OutlinedButton(
  onPressed: () async {
    // Save empty location if skipped
    if (location.isEmpty) {
      location = "";
    }
    await _handlePersonalDetails();
  },
  style: OutlinedButton.styleFrom(
    backgroundColor: Colors.white, // inside color
    side: const BorderSide(
      color: const Color(0xFF49329A), // outline color
      width: 1.5,
    ),
    padding: const EdgeInsets.symmetric(vertical: 15),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: Text(
    'Skip',
    style: TextStyle(
      color: const Color(0xFF49329A), // text color
      fontFamily: AppConstants.commonFont,
      fontWeight: FontWeight.bold,
    ),
  ),
),

                  ),
                  if(!widget.isFromProfile)
                  SizedBox(width: 15),
                  
                  // Done Button (disabled until location is fetched)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (location.isNotEmpty) ? () async {
                        await _handlePersonalDetails();
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (location.isNotEmpty) ? const Color(0xFF49329A) : Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppConstants.commonFont,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}