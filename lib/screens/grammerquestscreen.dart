import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:picturo_app/utils/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../cubits/games_cubits/quest_game/quest_game_qtn_list_cubit.dart';
import '../cubits/get_coins_cubit/coins_cubit.dart';
import '../utils/common_app_bar.dart';
import '../utils/common_file.dart';

class GrammarQuestScreen extends StatefulWidget {
  final String? title;
  final String? imageUrl;
  final int questId;
  final int level;
  final int index;
  final List<GrammarQuestion> questions;
  const GrammarQuestScreen(
      {super.key,
      this.title,
      required this.questId,
      required this.level,
      required this.index,
      required this.questions,
      required this.imageUrl});

  @override
  _GrammarQuestScreenState createState() => _GrammarQuestScreenState();
}

class _GrammarQuestScreenState extends State<GrammarQuestScreen> {
  TextEditingController verbController = TextEditingController(text: "Verb");
  TextEditingController adverbController =
      TextEditingController(text: 'Adverb');
  TextEditingController adjectiveController =
      TextEditingController(text: 'Adjective');

  TextEditingController word1Controller = TextEditingController();
  TextEditingController word2Controller = TextEditingController();
  TextEditingController word3Controller = TextEditingController();

  Color word1Color = Colors.white;
  Color word2Color = Colors.white;
  Color word3Color = Colors.white;

  Color word1TextColor = Colors.black; // Default text color
  Color word2TextColor = Colors.black; // Default text color
  Color word3TextColor = Colors.black; // Default text color
  bool loading = false;

  late AudioPlayer _bgPlayer;
  late AudioPlayer _celebrationPlayer;
  bool showCountdown = true;
  int countdown = 3;

  @override
  void initState() {
    // TODO: implement initState
    context.read<CoinCubit>().useCoin(1);
    _bgPlayer = AudioPlayer();
    _celebrationPlayer = AudioPlayer();
    _startCountdown();
    super.initState();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      if (countdown > 1) {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          countdown--;
        });
        return true;
      } else {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          showCountdown = false;
        });
        _playBackgroundMusic();
        return false;
      }
    });
  }

  void _playBackgroundMusic() async {
    if (!pauseMusic) {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.play(AssetSource('audio/quest_gm_bg.mp3'));
    }
  }

  void _playCelebrationSound() async {
    if (!pauseMusic) {
      try {
        print('🎵 Attempting to play celebration sound...');

        // Stop any currently playing celebration sound first
        await _celebrationPlayer.stop();

        // Set the volume to maximum
        await _celebrationPlayer.setVolume(1.0);

        // Play the sound
        await _celebrationPlayer.play(AssetSource('audio/winning_sound_3.mp3'));

        print('✅ Celebration sound playing successfully');
      } catch (e) {
        print('❌ Error playing celebration sound: $e');
      }
    } else {
      print('🔇 Celebration sound skipped - music is paused');
    }
  }

  void _stopAllSounds() {
    _bgPlayer.stop();
    _celebrationPlayer.stop();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _stopAllSounds();
    super.dispose();
  }

  bool pauseMusic = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEEFFF),
      appBar: CommonAppBar(
        title: "Picture Grammar Quest",
        isBackbutton: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: InkWell(
                onTap: () {
                  if (pauseMusic == false) {
                    _bgPlayer.pause();
                    _celebrationPlayer.pause();
                  } else {
                    _bgPlayer.play(AssetSource('audio/quest_gm_bg.mp3'));
                  }
                  setState(() {
                    pauseMusic = !pauseMusic;
                  });
                },
                child: Icon(
                  (!pauseMusic) ? Icons.volume_up_outlined : Icons.volume_off,
                  color: Colors.white,
                )),
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFEEEFFF),
                    Color(0xFFFFF0D3),
                    Color(0xFFE7F8FF),
                    Color(0xFFEEEFFF)
                  ], // Set your gradient colors here
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImageWidget(
                        imageUrl:
                            "https://picturoenglish.com/admin/uploads/${widget.imageUrl?.split("/").last}",
                        height: MediaQuery.of(context).size.width *
                            0.65, // Responsive height
                        width: MediaQuery.of(context).size.width *
                            0.65, // Responsive width
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      "${widget.title}",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins Regular'),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    Column(
                      children: [
                        buildTextFieldRow("Verb", verbController,
                            word1Controller, "ran", word1Color, word1TextColor),
                        SizedBox(height: 10),
                        buildTextFieldRow(
                            "Adverb",
                            adverbController,
                            word2Controller,
                            "quickly",
                            word2Color,
                            word2TextColor),
                        SizedBox(height: 10),
                        buildTextFieldRow(
                            "Adjective",
                            adjectiveController,
                            word3Controller,
                            "Alley",
                            word3Color,
                            word3TextColor),
                      ],
                    ),
                    SizedBox(height: 50),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            checkValues();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF49329A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 40),
                        ),
                        child: (loading)
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 0.8,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "Submit",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'Poppins Regular',
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showCountdown)
            Positioned(
              child: Container(
                height: double.infinity,
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Text(
                    "$countdown",
                    style: TextStyle(
                      fontSize: 100,
                      color: Colors.white,
                      fontFamily: AppConstants.commonFont,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildTextFieldRow(
      String label,
      TextEditingController leftController,
      TextEditingController rightController,
      String correctValue,
      Color fillColor,
      Color textColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              readOnly: leftController == verbController ||
                  leftController == adverbController ||
                  leftController == adjectiveController,
              controller: leftController,
              decoration: InputDecoration(
                hintText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      8), // Border radius for the focused state
                  borderSide:
                      BorderSide(color: Color(0xFF49329A)), // Border color
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      8), // Border radius for the enabled state
                  borderSide: BorderSide(
                      color: Color(0xFF49329A)), // Border color when enabled
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      8), // Border radius for the focused state
                  borderSide: BorderSide(
                      color: Color(0xFF49329A)), // Border color when focused
                ),
                filled: true,
                fillColor: Color(0xFFE3F1FF),
              ),
              style: TextStyle(
                  fontFamily: 'Poppins Regular',
                  color: Color(0xFF49329A),
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 10),
          Text("→",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins Regular')),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: rightController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      8), // Border radius for the focused state
                  borderSide:
                      BorderSide(color: Color(0xFFC1C1C1)), // Border color
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      8), // Border radius for the enabled state
                  borderSide: BorderSide(
                      color: Color(0xFFC1C1C1)), // Border color when enabled
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      8), // Border radius for the focused state
                  borderSide: BorderSide(
                      color: Color(0xFFC1C1C1)), // Border color when focused
                ),
                filled: true,
                fillColor: fillColor,
              ),
              style: TextStyle(
                  fontFamily: 'Poppins Regular',
                  color: textColor), // Dynamic text color
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showCongratulationsPopup() {
    final bool hasNextLevel = widget.index + 1 < widget.questions.length;

    _playCelebrationSound();

    // Trigger vibration once
    Vibration.hasVibrator().then((hasVibrator) {
      if (hasVibrator ?? false) {
        Vibration.vibrate(duration: 200);
      }
    });

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                // Gradient background
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5E3FA0), Color(0xFF9B59B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // Confetti (full-screen)
                Lottie.asset(
                  'assets/lottie/Confetti Effects Lottie Animation.json',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  repeat: true,
                ),

                // Foreground content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Congratulations!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins Medium',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Lottie.asset(
                        'assets/lottie/trophy (1).json',
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.7,
                        fit: BoxFit.contain,
                        repeat: false,
                      ),
                      const SizedBox(height: 20),

                      Text(
                        hasNextLevel
                            ? "You matched all correctly.\nReady for the next level?"
                            : "You matched all correctly. 🎉\nGame Completed!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'Poppins Medium',
                        ),
                      ),
                      const SizedBox(height: 30),

                      // OK button
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                              ),
                              onPressed: () {
                                _celebrationPlayer.stop();

                                Navigator.pop(context); // Close popup
                                Navigator.pop(
                                    context); // Back to previous screen
                              },
                              child: const Text(
                                "OK",
                                style: TextStyle(
                                  color: Color(0xFF5E3FA0),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins Medium',
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Next / Finish button
                            if (hasNextLevel)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 12),
                                ),
                                onPressed: () {
                                  _celebrationPlayer.stop();

                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GrammarQuestScreen(
                                        imageUrl: widget
                                            .questions[widget.index + 1]
                                            .image_path,
                                        questions: widget.questions,
                                        index: widget.index + 1,
                                        level: widget.level + 1,
                                        questId: widget.questId + 1,
                                        title: widget
                                            .questions[widget.index + 1]
                                            .gameQus,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Next Level",
                                  style: TextStyle(
                                    color: Color(0xFF5E3FA0),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins Medium',
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            else
                              const Text(
                                "🎉 Game Completed!",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontFamily: 'Poppins Medium',
                                ),
                              ),
                          ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void checkValues() async {
    setState(() {
      loading = true;
    });

    final url = Uri.parse("http://picturoenglish.com/api/sentancecheck.php");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Replace with actual token
      },
      body: jsonEncode({
        "sentence_id": widget.questId,
        "verb": word1Controller.text.trim(),
        "adverb": word2Controller.text.trim(),
        "adjective": word3Controller.text.trim(),
      }),
    );
    print("ajdscsldkcmskldmc ${widget.level} ${{
      "sentence_id": widget.questId,
      "verb": word1Controller.text.trim(),
      "adverb": word2Controller.text.trim(),
      "adjective": word3Controller.text.trim(),
    }} __  ");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result'];

      setState(() {
        word1Color =
            result['verb'] == 'Correct' ? Color(0xFF00C02D) : Color(0xFFC01515);
        word2Color = result['adverb'] == 'Correct'
            ? Color(0xFF00C02D)
            : Color(0xFFC01515);
        word3Color = result['adjective'] == 'Correct'
            ? Color(0xFF00C02D)
            : Color(0xFFC01515);
        if (result['verb'] == 'Correct' &&
            result['adverb'] == 'Correct' &&
            result['adjective'] == 'Correct') {
          makrAsCompleted();
        }

        word1TextColor =
            result['verb'] == 'Correct' ? Colors.white : Colors.black;
        word2TextColor =
            result['adverb'] == 'Correct' ? Colors.white : Colors.black;
        word3TextColor =
            result['adjective'] == 'Correct' ? Colors.white : Colors.black;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking sentence.')),
      );
    }
    setState(() {
      loading = false;
    });
  }

  void makrAsCompleted() async {
    final url = Uri.parse(
        "http://picturoenglish.com/api/grammer_quest_Levelcomplete.php");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Replace with actual token
      },
      body: jsonEncode({"level": widget.questId}),
    );
    print("ajdscsldkcmskldmc ${{"level": widget.questId}} __  ");

    if (response.statusCode == 200) {
      context
          .read<GrammarQuestCubit>()
          .fetchGrammarQuestions(levelFrom: widget.level + 1);
      _showCongratulationsPopup();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking sentence.')),
      );
    }
    setState(() {
      loading = false;
    });
  }
}
