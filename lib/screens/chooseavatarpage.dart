import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:picturo_app/responses/avatar_response.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/services/avatarcacheservice.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  _AvatarSelectionScreenState createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  int selectedAvatarIndex = -1;
  List<String> avatarImages = [];
  List<int> avatarIds = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final String baseUrl = "https://picturoenglish.com/admin/";
  bool _isSaving = false; // Track saving state
  String? currentUserId;
  final AvatarCacheService _avatarCache = AvatarCacheService();

  @override
  void initState() {
    super.initState();
    fetchAvatarsAndUpdateImages();
  }

   Future<void> fetchAvatarsAndUpdateImages() async {
    try {
      final response = await _avatarCache.getAvatars();

      List<String> avatarUrls = response.data
          .map((avatar) => baseUrl + avatar.avatarUrl)
          .toList();
      
      List<int> ids = response.data
          .map((avatar) => avatar.id)
          .toList();

      setState(() {
        avatarImages = avatarUrls;
        avatarIds = ids;
        _isLoading = false;
        if (avatarImages.isNotEmpty) {
          selectedAvatarIndex = 0;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching avatars: $e";
        _isLoading = false;
      });
      print("Error fetching avatars: $e");
    }
  }

  Future<void> _saveSelectedAvatar() async {
  if (selectedAvatarIndex == -1) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please select an avatar")),
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    // Get the actual avatar ID from the stored list
    int avatarId = avatarIds[selectedAvatarIndex];
    final apiService = await ApiService.create();

    final prefs = await SharedPreferences.getInstance();
  currentUserId = prefs.getString('user_id');

    print('UserId: $currentUserId');
    print('AvatarId: $avatarId');

    final result = await apiService.updateAvatar(
      userId: currentUserId!,
      avatarId: avatarId,
    );

    setState(() {
      _isSaving = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Avatar updated successfully!")),
      );
      Navigator.pop(context, avatarId); // Return success to previous screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? "Failed to update avatar")),
      );
    }
  } catch (e) {
    setState(() {
      _isSaving = false;
    });
    print("Error exception: ${e.toString()}"); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${e.toString()}")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Row(
              children: [
                Text(
                  'Choose Avatar',
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
        child: Column(
          children: [
            SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: _isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.white,
                        ),
                      )
                    : avatarImages.isEmpty
                        ? Icon(Icons.person, size: 50, color: Colors.grey)
                        : CircleAvatar(
                            radius: 55,
                            backgroundImage: CachedNetworkImageProvider(
                              avatarImages[selectedAvatarIndex],
                            ),
                          ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Avatars",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins Regular',
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? _buildShimmerGrid()
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage))
                      : avatarImages.isEmpty
                          ? Center(child: Text("No avatars available"))
                          : GridView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                              ),
                              itemCount: avatarImages.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedAvatarIndex = index;
                                    });
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: selectedAvatarIndex == index
                                        ? Color(0xFF49329A)
                                        : Colors.transparent,
                                    child: CircleAvatar(
                                      radius: 36,
                                      backgroundImage: CachedNetworkImageProvider(
                                        avatarImages[index],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Color(0xFF49329A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Color(0xFF49329A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins Regular',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Save Button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF49329A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      onPressed: _isSaving ? null : _saveSelectedAvatar,
                      child: _isSaving
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Save",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins Regular',
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
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: 8, // Show 8 shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
          ),
        );
      },
    );
  }
}