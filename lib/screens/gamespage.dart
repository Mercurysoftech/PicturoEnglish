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

import '../cubits/game_view_cubit/game_view_cubit.dart';
import '../cubits/get_avatar_cubit/get_avatar_cubit.dart';
import '../utils/common_app_bar.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
// Store fetched game names

  String _errorMessage = ''; // Store error messages

  @override
  void initState() {
    super.initState();
    context.read<GameCubit>().fetchGamesAndUpdateGrid();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE5EEFF),
      appBar: CommonAppBar(title:"Games" ,isFromHomePage: true,),
      body: BlocBuilder<GameCubit, GameState>(
  builder: (context, gameState) {
    if(gameState is GameLoaded){
      List<String> gameNames =gameState.gameNames;
      return Container(
        margin: EdgeInsets.only(top: 12),
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
          child: ListView(
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
                  gameNames.isNotEmpty ? gameNames[1] : "Drag and Learn", // Use fetched game name
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
                  gameNames.length > 1 ? gameNames[0] : "Picture Grammar Quest", // Use fetched game name
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
                  gameNames.length > 2 ? gameNames[2] : "Action Snap", // Use fetched game name
                  "Take a correct action verb snaps",
                ),
              ),
            ],
          ),
        ),
      );
    }else{
      return Center(child: CircularProgressIndicator());
    }

  },
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