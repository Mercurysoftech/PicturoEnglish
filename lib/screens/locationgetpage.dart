import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Import geocoding package

class LocationGetPage extends StatefulWidget {
  const LocationGetPage({super.key});

  @override
  _LocationGetPageState createState() => _LocationGetPageState();
}

class _LocationGetPageState extends State<LocationGetPage> {
  String locationMessage = "Location not found";
  bool isLoading = false;  // Add isLoading to manage the progress bar visibility
  String gender = ""; // Provide a default value
  String age = "";
  String qualification = "";
  String languageLevel = "";
  String purpose = "";
  String location = "";
  String reason="";
  String selectedLanguage="";



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
    selectedLanguage=prefs.getString("selectedLanguage")?? "";
  });

  // Log loaded values for debugging
  print("Loaded: Gender = $gender, Age = $age");
  print("Qualification = $qualification");
  print("Language Level = $languageLevel");
  print("Purpose = $purpose");
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Homepage()),
          (route) => false,
    );

  } else {
    _showMessage(result["error"] ?? "Something went wrong. Please try again.");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Homepage()),
          (route) => false,
    );

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

  
      await _handlePersonalDetails();
  

     

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
    // Check permission when the widget is first built
    _handleLocationPermission();
    _loadSavedData();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
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

              // Show the progress bar while loading
              if (isLoading)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF49329A)), // Optional: Customize the color of progress bar
                )
              else
                Text(
                  locationMessage,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),

              // "Turn on Location" Button
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
                    'Get Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins Medium',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
