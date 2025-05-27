import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/responses/games_response.dart';
import 'package:picturo_app/screens/actionsnappage.dart';
import 'package:picturo_app/screens/actionsnaptopics.dart';
import 'package:picturo_app/screens/dragandlearnpage.dart';
import 'package:picturo_app/screens/dragandlearntopics.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/screens/picturegrammerquest.dart';
import 'package:picturo_app/screens/picturegrammerquesttopics..dart';
import 'package:picturo_app/services/api_service.dart';

import '../cubits/get_avatar_cubit/get_avatar_cubit.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  List<String> _gameNames = []; // Store fetched game names
  bool _isLoading = true; // Track loading state
  String _errorMessage = ''; // Store error messages

  @override
  void initState() {
    super.initState();
    fetchBooksAndUpdateGrid(); // Fetch data when the widget is initialized
  }

  Future<void> fetchBooksAndUpdateGrid() async {
    try {
      // Fetch the games data
      final apiService = await ApiService.create();
      GamesResponse gamesResponse = await apiService.fetchGames();

      // Extract the game names from the response
      List<String> gameNames = gamesResponse.data.map((game) => game.gameName).toList();

      // Update the state with the fetched game names
      setState(() {
        _gameNames = gameNames;
        _isLoading = false; // Data fetching is complete
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching games: $e"; // Store the error message
        _isLoading = false; // Data fetching failed
      });
      print("Error fetching games: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE5EEFF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF49329A),
          title: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Row(
              children: [
                Text(
                  'Games',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins Regular',
                  ),
                ),
              ],
            ),
          ),
          actions: [
  Padding(
    padding: const EdgeInsets.only(top: 10.0, right: 24.0),
    child: BlocBuilder<AvatarCubit, AvatarState>(
      builder: (context, state) {
        if (state is AvatarLoaded) {
          return InkWell(
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFF49329A),
              backgroundImage: state.imageProvider,
            ),
          );
        } else if (state is AvatarLoading) {
          return const CircularProgressIndicator();
        } else {
          // Fallback image
          final fallback = context.read<AvatarCubit>().getFallbackAvatarImage();
          return CircleAvatar(
            backgroundImage: fallback,
            radius: 40,
          );
        }
      },
    ),
  ),
],
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
        child: Padding(
          padding: const EdgeInsets.only(left: 15,right: 15,top: 5),
          child: _isLoading
              ? Center(child: CircularProgressIndicator()) // Show loading indicator
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage)) // Show error message
                  : ListView(
                      children: [
                        // Drag and Learn Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DragandLearnTopicScreen(gameName:'Drag and Learn'),
                              ),
                            );
                          },
                          child: buildBlurImageCard(
                            'assets/game2.png',
                            _gameNames.isNotEmpty ? _gameNames[1] : "Drag and Learn", // Use fetched game name
                            "Match the correct picture and word",
                          ),
                        ),
                        SizedBox(height: 20),
                        // Picture Grammar Quest Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PictureGrammarQuestScreen(),
                              ),
                            );
                          },
                          child: buildBlurImageCard(
                            'assets/game1.png',
                            _gameNames.length > 1 ? _gameNames[0] : "Picture Grammar Quest", // Use fetched game name
                            "Find the correct verb, adverb, and adjective",
                          ),
                        ),
                        SizedBox(height: 20),
                        // Action Snap Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActionSnapTopicsScreen(gameName:'Action Snap',),
                              ),
                            );
                          },
                          child: buildBlurImageCard(
                            'assets/game3.png',
                            _gameNames.length > 2 ? _gameNames[2] : "Action Snap", // Use fetched game name
                            "Take a correct action verb snaps",
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

Future<String> _getCurrentUserAvatar() async {
  try {
    final apiService = await ApiService.create();
    final profile = await apiService.fetchProfileDetails();
    
    if (profile.avatarId == null || profile.avatarId == 0) {
      throw Exception('Using default avatar');
    }
    
    final avatarResponse = await apiService.fetchAvatars();
    final avatar = avatarResponse.data.firstWhere(
      (a) => a.id == profile.avatarId,
      orElse: () => throw Exception('Avatar not found'),
    );
    
    return 'https://picturoenglish.com/admin/${avatar.avatarUrl}';
  } catch (e) {
    print('Error fetching current user avatar: $e');
    throw e; // This will trigger the default avatar fallback
  }
}

Widget buildBlurImageCard(String imageUrl, String title, String subtitle) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Stack(
      children: [
        // Background Image
        Image.asset(
          imageUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
        // Blurred Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: RepaintBoundary( // Add RepaintBoundary here
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(15),
                bottom: Radius.circular(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white, // Color of the top line
                        width: 0.5, // Thickness of the top line
                      ),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      title,
                      style: TextStyle(
                        color: Color(0xFF49329A),
                        fontSize: 16,
                        fontFamily: 'Poppins black',
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: TextStyle(
                        color: Color(0xFF49329A),
                        fontSize: 12,
                        fontFamily: 'Poppins Regular',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF49329A),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}