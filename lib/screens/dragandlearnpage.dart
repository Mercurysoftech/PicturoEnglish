import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:picturo_app/screens/dragandlearntopics.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:picturo_app/utils/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../cubits/drag_and_learn_cubit/drag_and_learn_cubit.dart';
import '../cubits/get_coins_cubit/coins_cubit.dart';
import '../models/dragand_learn_model.dart';
import '../utils/common_file.dart';

class ImageWithMeaning {
  final String? imagePath;
  final String? meaning;

  ImageWithMeaning({this.imagePath, this.meaning});
}

class DragAndLearnApp extends StatefulWidget {
  const DragAndLearnApp(
      {super.key,
      required this.level,
      required this.bookId,
      required this.topicId,
      required this.levelIndex,
      required this.preLevels});
  final Levels? level;
  final int? bookId;
  final int? topicId;
  final int levelIndex;
  final List<Levels>? preLevels;

  @override
  _DragAndLearnAppState createState() => _DragAndLearnAppState();
}

class _DragAndLearnAppState extends State<DragAndLearnApp> {
  late List<String?> words;
  late List<ImageWithMeaning> imagesWithMeanings;
  late List<String?> images;
  Map<String?, String?> placedImages = {};
  List<String?> availableImages = [];
  late Map<String?, String?> imageMeanings = {};
  List<ImageWithMeaning> availableImagesWithMeanings = [];

  late AudioPlayer _bgPlayer;
  late AudioPlayer _effectPlayer;
  late AudioPlayer _effectDropPlayer;
  late AudioPlayer _celebrationPlayer;

  bool showCountdown = true;
  int countdown = 3;

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _currentSnackbar;

  @override
  void initState() {
    super.initState();
    context.read<CoinCubit>().useCoin(1);
    _bgPlayer = AudioPlayer();
    _effectPlayer = AudioPlayer();
    _effectDropPlayer = AudioPlayer();
    _celebrationPlayer = AudioPlayer();

    if (widget.level?.questions != null) {
      words = widget.level!.questions!.map((q) => q.question).toList();

      imagesWithMeanings = widget.level!.questions!
          .map((q) =>
              ImageWithMeaning(imagePath: q.qusImage, meaning: q.meaning))
          .toList();
    }

    for (var word in words) {
      placedImages[word] = null;
    }

    availableImagesWithMeanings = List.from(imagesWithMeanings)..shuffle();

    _startCountdown();
  }

  // Method to show snackbar and keep it visible
  void _showMeaningSnackbar(String meaning) {
    // Dismiss any existing snackbar
    if (_currentSnackbar != null) {
      _currentSnackbar!.close();
    }

    _currentSnackbar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          meaning,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: AppConstants.commonFont,
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        duration: Duration(days: 1), // Very long duration to keep it visible
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _hideMeaningSnackbar() {
    if (_currentSnackbar != null) {
      _currentSnackbar!.close();
      _currentSnackbar = null;
    }
  }

  Future<void> markQuestionAsRead({
    required int bookId,
    required int topicId,
    required int questionId,
    required bool isRead,
  }) async {
    final url =
        Uri.parse('https://picturoenglish.com/api/dragandlearn_qusupdate.php');
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");

    final headers = {
      "Authorization": "Bearer $token",
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'book_id': bookId,
      'topic_id': topicId,
      'question_id': questionId,
      'is_read': isRead,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print('✅ Question marked as read: ${response.body}');
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('🚨 Error sending request: $e');
    }
  }

  Future<void> markLevelAsCompleted({
    required int bookId,
    required int topicId,
    required int level,
  }) async {
    final url =
        Uri.parse('https://picturoenglish.com/api/markleveldragandlearn.php');
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");
    final headers = {
      "Authorization": "Bearer $token",
      'Content-Type': 'application/json',
      // Add any other headers like Authorization if needed
    };

    final body = jsonEncode({
      'book_id': bookId,
      'topic_id': widget.topicId,
      'level': level,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print('✅ Level marked as completed __ : ${body} && ${response.body}');
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('🚨 Error sending request: $e');
    }
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
      await _bgPlayer.play(AssetSource('audio/bg_music.mp3'));
    }
  }

  void _playEffect(String fileName) async {
    await _effectPlayer.play(AssetSource('audio/$fileName'));
  }

  void _playDropEffect(String fileName) async {
    await _effectDropPlayer.play(AssetSource('audio/$fileName'));
  }

  void _playCelebrationSound() async {
    if (!pauseMusic) {
      try {
        print('🎵 Attempting to play celebration sound...');

        // Check if this is the final level
        final bool hasNextLevel =
            widget.levelIndex + 1 < (widget.preLevels?.length ?? 0);
        final bool nextLevelIsPlayable = hasNextLevel &&
            (widget.preLevels?[widget.levelIndex + 1].questions?.length ?? 0) >=
                4;

        final bool isFinalLevel = !nextLevelIsPlayable;

        // Stop any currently playing celebration sound first
        await _celebrationPlayer.stop();

        // Set the volume to maximum
        await _celebrationPlayer.setVolume(1.0);

        // Choose sound based on whether it's the final level or not
        String soundFile;
        if (isFinalLevel) {
          soundFile = 'audio/winning_sound_1.mp3';
          print('🏆 Final level - playing game completion sound');
        } else {
          soundFile = 'audio/winning_sound_2.mp3';
          print('⭐ Regular level - playing winning sound');
        }

        await _celebrationPlayer.play(AssetSource(soundFile));

        print('✅ Celebration sound playing successfully: $soundFile');
      } catch (e) {
        print('❌ Error playing celebration sound: $e');

        // Fallback: try alternative sound files
        try {
          await _celebrationPlayer.stop();
          final bool hasNextLevel =
              widget.levelIndex + 1 < (widget.preLevels?.length ?? 0);
          final bool nextLevelIsPlayable = hasNextLevel &&
              (widget.preLevels?[widget.levelIndex + 1].questions?.length ??
                      0) >=
                  4;

          final bool isFinalLevel = !nextLevelIsPlayable;

          String fallbackSound = isFinalLevel
              ? 'audio/winning_sound_2.mp3'
              : 'audio/winning_sound_1.mp3';

          await _celebrationPlayer.play(AssetSource(fallbackSound));
          print('✅ Fallback sound playing: $fallbackSound');
        } catch (e2) {
          print('❌ Fallback sound also failed: $e2');
        }
      }
    } else {
      print('🔇 Celebration sound skipped - music is paused');
    }
  }

  void _stopAllSounds() {
    _bgPlayer.stop();
    _effectPlayer.stop();
    _effectDropPlayer.stop();
    _celebrationPlayer.stop();
  }

  @override
  void dispose() {
    _stopAllSounds();
    _hideMeaningSnackbar();
    super.dispose();
  }

  bool pauseMusic = false;

  void _showCongratulationsPopup() {
    // Play celebration sound when popup shows
    _playCelebrationSound();

    final bool hasNextLevel =
        widget.levelIndex + 1 < (widget.preLevels?.length ?? 0);

    final bool nextLevelIsPlayable = hasNextLevel &&
        (widget.preLevels?[widget.levelIndex + 1].questions?.length ?? 0) >= 4;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                // ---------- Gradient background ----------
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

                // ---------- Confetti BG only when game completed ----------
                if (!nextLevelIsPlayable)
                  Lottie.asset(
                    'assets/lottie/confetti on transparent background.json', // background celebration
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    repeat: true,
                  ),

                // ---------- Foreground content ----------
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Choose Winner or Trophy
                      Lottie.asset(
                        nextLevelIsPlayable
                            ? 'assets/lottie/Winner.json'
                            : 'assets/lottie/Trophy.json',
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.7,
                        fit: BoxFit.contain,
                        repeat: false,
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 10),
                      Text(
                        nextLevelIsPlayable
                            ? "You matched all correctly. Ready for the next level?"
                            : "You matched all correctly. 🎉\nGame Completed!",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'Poppins Medium',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

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
                                  context); // Go back to previous screen
                            },
                            child: const Text(
                              "OK",
                              style: TextStyle(
                                color: Color(0xFF5E3FA0),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Poppins Medium',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          if (nextLevelIsPlayable)
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
                                    builder: (context) => DragAndLearnApp(
                                      levelIndex: widget.levelIndex + 1,
                                      topicId: widget.topicId,
                                      bookId: widget.bookId,
                                      level: widget
                                          .preLevels?[widget.levelIndex + 1],
                                      preLevels: widget.preLevels,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "Next Level",
                                style: TextStyle(
                                  color: Color(0xFF5E3FA0),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'Poppins Medium',
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Only show Next Level button if more levels
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

  bool isVolumeMute = true;
  Map<String?, bool> incorrectDrop = {};

  @override
  Widget build(BuildContext context) {
    double itemSize = 100;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        _stopAllSounds();
        _hideMeaningSnackbar();
        context
            .read<DragLearnCubit>()
            .fetchDragLearnData(bookId: widget.bookId ?? 0, isLoading: true);
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F1E6),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(66),
          child: AppBar(
            backgroundColor: Color(0xFF49329A),
            leading: Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 24.0),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
                onPressed: () {
                  _hideMeaningSnackbar();
                  context.read<DragLearnCubit>().fetchDragLearnData(
                      bookId: widget.bookId ?? 0, isLoading: true);
                  Navigator.pop(context);
                },
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: InkWell(
                    onTap: () {
                      if (pauseMusic == false) {
                        _bgPlayer.pause();
                        _celebrationPlayer.pause();
                      } else {
                        _bgPlayer.play(AssetSource('audio/bg_music.mp3'));
                      }
                      setState(() {
                        pauseMusic = !pauseMusic;
                      });
                    },
                    child: Icon(
                      (!pauseMusic)
                          ? Icons.volume_up_outlined
                          : Icons.volume_off,
                      color: Colors.white,
                    )),
              )
            ],
            title: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Drag and Learn',
                style: TextStyle(
                    fontFamily: AppConstants.commonFont,
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ), // shape: RoundedRectangleBorder(
            //
            // ),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  Text("Level ${widget.levelIndex + 1}",
                      style: TextStyle(
                          fontFamily: AppConstants.commonFont,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  // SizedBox(
                  //   height: itemSize * 2 + 50,
                  //   child: GridView.builder(
                  //     shrinkWrap: true,
                  //     physics: NeverScrollableScrollPhysics(),
                  //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  //       crossAxisCount: 3,
                  //       crossAxisSpacing: 15,
                  //       mainAxisSpacing: 15,
                  //       childAspectRatio: 1,
                  //     ),
                  //
                  //     itemCount: words.length,
                  //     itemBuilder: (context, index) {
                  //       String? word = words[index];
                  //       return DragTarget<String>(
                  //         onWillAcceptWithDetails: (data) => true,
                  //         onAccept: (imagePath) async{
                  //           int wordIndex = words.indexOf(word);
                  //           _playDropEffect('drop.mp3');
                  //          await markQuestionAsRead(bookId: widget.bookId??0, topicId: widget.topicId??0, questionId: widget.level?.questions?[wordIndex].id??0, isRead: true);
                  //
                  //           int imageIndex = images.indexOf(imagePath);
                  //           if (wordIndex == imageIndex) {
                  //             setState(() {
                  //               placedImages[word] = imagePath;
                  //               availableImages.remove(imagePath);
                  //             });
                  //           }
                  //           if (placedImages.values.every((value) => value != null)) {
                  //             await markLevelAsCompleted(bookId: widget.bookId??0, topicId: widget.topicId??0, level: widget.level?.level??0);
                  //             await Future.delayed(Duration(milliseconds: 300), _showCongratulationsPopup);
                  //           }else {
                  //             setState(() {
                  //               incorrectDrop[word] = true;
                  //             });
                  //             _playDropEffect('wrong.mp3'); // optional wrong sound
                  //             // Optional: Show error message
                  //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  //               content: Text('Oops! That’s not the correct match.'),
                  //               backgroundColor: Colors.red,
                  //             ));
                  //           }
                  //         },
                  //         builder: (context, candidateData, rejectedData) {
                  //           return Container(
                  //             decoration: BoxDecoration(
                  //               color: Colors.white,
                  //               borderRadius: BorderRadius.circular(12),
                  //               border: Border.all(color: Color(0xFFCBBCFF), width: 1),
                  //             ),padding: EdgeInsets.all(5),
                  //
                  //             alignment: Alignment.center,
                  //             child: placedImages[word] != null
                  //                 ? ClipRRect(
                  //               borderRadius: BorderRadius.circular(12),
                  //               child: CachedNetworkImageWidget(
                  //                imageUrl:  "https://picturoenglish.com/admin/${placedImages[word]!}",
                  //                 fit: BoxFit.cover,
                  //               ),
                  //             )
                  //                 : Text(word ?? '',
                  //                   textAlign: TextAlign.center,
                  //
                  //                   style: TextStyle(
                  //                   fontFamily: AppConstants.commonFont,fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF49329A)),
                  //                                               ),
                  //           );
                  //         },
                  //       );
                  //     },
                  //   ),
                  // ),
                  ImageWordMatchGrid(
                    words: words,
                    imagesWithMeanings: imagesWithMeanings, // Updated parameter
                    placedImages: placedImages,
                    availableImagesWithMeanings:
                        availableImagesWithMeanings, // Updated parameter
                    incorrectDrop: incorrectDrop,
                    itemSize: itemSize,
                    onAccept: (imagePath, wordIndex, word) async {
                      _playDropEffect('drop.mp3');

                      await markQuestionAsRead(
                        bookId: widget.bookId ?? 0,
                        topicId: widget.topicId ?? 0,
                        questionId: widget.level?.questions?[wordIndex].id ?? 0,
                        isRead: true,
                      );

                      // Find the index in the original images list
                      int imageIndex = imagesWithMeanings
                          .indexWhere((img) => img.imagePath == imagePath);
                      if (wordIndex == imageIndex) {
                        setState(() {
                          placedImages[word] = imagePath;
                          availableImagesWithMeanings
                              .removeWhere((img) => img.imagePath == imagePath);
                          incorrectDrop[word] = false;
                        });

                        if (placedImages.values
                            .every((value) => value != null)) {
                          await markLevelAsCompleted(
                            bookId: widget.bookId ?? 0,
                            topicId: widget.topicId ?? 0,
                            level: widget.level?.level ?? 0,
                          );
                          await Future.delayed(Duration(milliseconds: 300),
                              _showCongratulationsPopup);
                        }
                      } else {
                        setState(() {
                          incorrectDrop[word] = true;
                        });

                        _playDropEffect('wrong.mp3');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Oops! That’s not the correct match.'),
                            backgroundColor: Colors.red,
                          ),
                        );

                        if (await Vibration.hasVibrator() ?? false) {
                          Vibration.vibrate(duration: 300);
                        }

                        Future.delayed(Duration(seconds: 1), () {
                          setState(() {
                            incorrectDrop[word] = false;
                          });
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF49329A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Drag and place the picture into the correct container  &  Hold your finger on the picture and watch the magic word appear!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: AppConstants.commonFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: itemSize * 2 + 50,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1,
                      ),
                      itemCount: availableImagesWithMeanings.length,
                      itemBuilder: (context, index) {
                        final imageWithMeaning =
                            availableImagesWithMeanings[index];

                        return _DraggableWithTooltip(
                            imagePath: imageWithMeaning.imagePath,
                            meaning: imageWithMeaning.meaning,
                            itemSize: itemSize,
                            onDragStarted: () => _playEffect('drag.mp3'),
                            onLongPressStart: () {
                              // Show meaning when long press starts
                              _showMeaningSnackbar(
                                  imageWithMeaning.meaning ?? '');
                            },
                            onLongPressEnd: (_) {
                              // Hide meaning when long press ends
                              _hideMeaningSnackbar();
                            });
                      },
                    ),
                  )
                ],
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
      ),
    );
  }
}

class ImageWordMatchGrid extends StatelessWidget {
  final List<String?> words;
  final List<ImageWithMeaning> imagesWithMeanings;
  final Map<String?, String?> placedImages;
  final List<ImageWithMeaning> availableImagesWithMeanings;
  final Map<String?, bool> incorrectDrop;
  final double itemSize;
  final Function(String imagePath, int wordIndex, String? word) onAccept;

  const ImageWordMatchGrid({
    super.key,
    required this.words,
    required this.imagesWithMeanings,
    required this.placedImages,
    required this.availableImagesWithMeanings,
    required this.incorrectDrop,
    required this.itemSize,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemSize * 2 + 50,
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1,
        ),
        itemCount: words.length,
        itemBuilder: (context, index) {
          String? word = words[index];
          bool isIncorrect = incorrectDrop[word] == true;

          return DragTarget<String>(
            onWillAcceptWithDetails: (data) => true,
            onAccept: (imagePath) => onAccept(imagePath, index, word),
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isIncorrect ? Colors.red : const Color(0xFFCBBCFF),
                    width: isIncorrect ? 3 : 1,
                  ),
                  boxShadow: [
                    if (candidateData.isNotEmpty)
                      const BoxShadow(
                        color: Color(0xFFCBBCFF),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                alignment: Alignment.center,
                child: placedImages[word] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 1, 
                            child: Image.network(
                              "https://picturoenglish.com/admin/${placedImages[word]!}",
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image,
                                      color: Colors.grey),
                            ),
                          ),
                        ))
                    : Text(
                        word ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppConstants.commonFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF49329A),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DraggableWithTooltip extends StatefulWidget {
  final String? imagePath;
  final String? meaning;
  final double itemSize;
  final VoidCallback onDragStarted;
  final VoidCallback onLongPressStart;
  final Function(LongPressEndDetails) onLongPressEnd;

  const _DraggableWithTooltip({
    required this.imagePath,
    required this.meaning,
    required this.itemSize,
    required this.onDragStarted,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  __DraggableWithTooltipState createState() => __DraggableWithTooltipState();
}

class __DraggableWithTooltipState extends State<_DraggableWithTooltip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() => _isPressed = true);
        widget.onLongPressStart();
      },
      onLongPressEnd: (details) {
        setState(() => _isPressed = false);
        widget.onLongPressEnd(details);
      },
      child: Draggable<String>(
        data: widget.imagePath,
        onDragStarted: widget.onDragStarted,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: widget.itemSize,
            height: widget.itemSize,
            child: CachedNetworkImageWidget(
                imageUrl:
                    "https://picturoenglish.com/admin/${widget.imagePath ?? ''}",
                fit: BoxFit.cover),
          ),
        ),
        childWhenDragging: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isPressed ? Colors.blue.withOpacity(0.1) : Colors.white,
            border:
                _isPressed ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                CachedNetworkImageWidget(
                    imageUrl:
                        "https://picturoenglish.com/admin/${widget.imagePath ?? ''}",
                    fit: BoxFit.cover),
                if (_isPressed)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
