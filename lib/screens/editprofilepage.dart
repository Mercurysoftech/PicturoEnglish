import 'package:flutter/material.dart';
import 'package:picturo_app/screens/changepasswordpage.dart';
import 'package:picturo_app/screens/chooseavatarpage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfile extends StatefulWidget {
   final int? profileId;
   final String? userName;
   final String? email;
   final int? mobile;

  const EditProfile({super.key, this.profileId, this.userName, this.email, this.mobile});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  String? _avatarUrl;
  ApiService? _apiService;
  bool _isLoading = true;
  int? _currentAvatarId;
  final String baseUrl = "https://picturoenglish.com/admin/";
  
  String? currentUserId;
 

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _mobileController = TextEditingController(text: widget.mobile.toString() ?? '');

    print('name: ${widget.userName} and Email: ${widget.email} and Mobile: ${widget.mobile} and ProfileId: ${widget.profileId}');
    
    // Parse profileUrl as avatarId if it exists
    _currentAvatarId = widget.profileId;
    
    // Initialize API service
    _initializeApiService();
  }

  Future<void> _initializeApiService() async {
    try {
      _apiService = await ApiService.create();
      if (_currentAvatarId != null) {
        await _loadAvatar();
      }
    } catch (e) {
      print("Error initializing API service: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _saveProfile() async {
  // Show loading indicator
  setState(() {
    _isLoading = true;
  });

  // Validate mobile number format if needed
if (_mobileController.text.isNotEmpty) {
  final mobileRegex = RegExp(r'^[0-9]{10}$');
  if (!mobileRegex.hasMatch(_mobileController.text)) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
    );
    return;
  }
}

  try {
    // Call the API to update profile
    final response = await _apiService!.updateProfile(
      username: _nameController.text,
      email: _emailController.text,
      mobile: _mobileController.text,
    );

    if (response['success'] == true) {
      // Profile updated successfully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Return updated data to previous screen
      if (mounted) {
        Navigator.pop(context, {
          'name': _nameController.text,
          'email': _emailController.text,
          'mobile': _mobileController.text,
          'avatar_id': _currentAvatarId,
        });
      }
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['error'] ?? 'Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('Error updating profile: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred while updating profile'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

 Future<void> _loadAvatar() async {
  if (_apiService == null || _currentAvatarId == null) {
    print('API service or avatar ID is null');
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  currentUserId = prefs.getString('user_id');
  
  try {
    print('Fetching avatars...');
    final avatarResponse = await _apiService!.fetchAvatars();
    
    // Debug: Print all avatars received
    print('Received ${avatarResponse.data.length} avatars:');
    avatarResponse.data.forEach((a) => print('Avatar ID: ${a.id}, URL: ${a.avatarUrl}'));
    
    // Find the matching avatar
    final avatar = avatarResponse.data.firstWhere(
      (a) => a.id == _currentAvatarId,
      orElse: () {
        print('Avatar with ID $_currentAvatarId not found');
        throw Exception("Avatar not found");
      },
    );
    
    print('Found matching avatar: ${avatar.id} - ${baseUrl+avatar.avatarUrl}');
    
    if (mounted) {
      setState(() {
        _avatarUrl = baseUrl+avatar.avatarUrl;
        print('Updated _avatarUrl to: $_avatarUrl');
      });
    }
  } catch (e) {
    print("Error loading avatar: $e");
    if (mounted) {
      setState(() {
        _avatarUrl = null;
      });
    }
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
     if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFE3F1FF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFE3F1FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // Increased app bar height
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0), // Adjust top padding
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0), // Adjust top padding
            child: Row(
              children: [
                Text(
                  'Edit Profile',
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
            Color(0xFFE0F7FF),
            Color(0xFFEAE4FF),
            ],
            begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          ),
        ),
      child:  SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: _getAvatarImage(),
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: 200,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AvatarSelectionScreen(),
                          settings: RouteSettings(
                            arguments: _currentAvatarId,
                          ),
                        ),
                      ).then((returnedValue) async {  // Changed this to handle the returned avatar ID
    if (returnedValue != null && returnedValue is int) {
      setState(() {
        _currentAvatarId = returnedValue;
      });
      await _loadAvatar();  // Load the new avatar immediately
    }
  });
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Color(0xFFFFFFFF),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Color(0xFF49329A)),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'Change Avatar',
                      style: TextStyle(
                        color: Color(0xFF49329A),
                        fontFamily: 'Poppins Regular',
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal:24, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Name',
                  style: TextStyle(
                    color: Color(0xFF49329A),
                    fontSize: 15,
                    fontFamily: 'Poppins Regular',
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color:
                            Color(0xFFDDDDDD)), // Blue Border when not focused
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Color(0xFF49329A),
                        width: 1), // Thicker Blue Border when focused
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email ID',
                  style: TextStyle(
                    color: Color(0xFF49329A),
                    fontSize: 15,
                    fontFamily: 'Poppins Regular',
                     fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color:
                            Color(0xFFDDDDDD)), // Blue Border when not focused
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Color(0xFF49329A),
                        width: 1), // Thicker Blue Border when focused
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mobile number',
                  style: TextStyle(
                    color: Color(0xFF49329A),
                    fontSize: 15,
                    fontFamily: 'Poppins Regular',
                     fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: TextFormField(
                keyboardType: TextInputType.number,
                maxLength: 10,
                controller: _mobileController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color:
                            Color(0xFFDDDDDD)), // Blue Border when not focused
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Color(0xFF49329A),
                        width: 1), // Thicker Blue Border when focused
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
              ),
            ),
            SizedBox(height: 26),
            Center(
              child: InkWell(
  child: Text(
    "Change Password",
    style: TextStyle(
      color: Color(0xFF49329A),
      decoration: TextDecoration.underline, // Add this line to underline the text
      fontFamily: 'Poppins Regular',
      fontWeight: FontWeight.bold
    ),
  ),
  onTap: () {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChangePasswordPage(emailId: widget.email,)), // Replace with your target page
      );
  },
),
            ),
            SizedBox(height: 60),
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF49329A),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Color(0xFF49329A)),
                      borderRadius:
                          BorderRadius.circular(9), // Rectangular shape
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.white,fontFamily: 'Poppins Regular',fontWeight: FontWeight.bold,fontSize: 16),
                  ),
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
  ImageProvider _getAvatarImage() {
  if (_currentAvatarId == null || _currentAvatarId == 0) {
    return AssetImage('assets/avatar2.png'); // Default avatar for null or 0
  } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
    return NetworkImage(_avatarUrl!);
  } else {
    return AssetImage('assets/avatar2.png'); // Fallback if URL is not valid
  }
}


  Future<void> _handleAvatarSelection(int newAvatarId) async {
    try {
      setState(() {
        _isLoading = true;
        _currentAvatarId = newAvatarId;
      });

      // Fetch the new avatar URL
      final avatarResponse = await _apiService!.fetchAvatars();
      final newAvatar = avatarResponse.data.firstWhere(
        (a) => a.id == newAvatarId,
        orElse: () => throw Exception("Selected avatar not found"),
      );

      setState(() {
        _avatarUrl = newAvatar.avatarUrl;
        _isLoading = false;
      });
    } catch (e) {
      print("Error handling avatar selection: $e");
      setState(() {
        _isLoading = false;
        _avatarUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load selected avatar")),
      );
    }
  }

}
