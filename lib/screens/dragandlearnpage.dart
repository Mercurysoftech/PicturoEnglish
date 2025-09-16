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
  late List<String?> images;
  Map<String?, String?> placedImages = {};
  List<String?> availableImages = [];

  late AudioPlayer _bgPlayer;
  late AudioPlayer _effectPlayer;
  late AudioPlayer _effectDropPlayer;

  bool showCountdown = true;
  int countdown = 3;

  @override
  void initState() {
    super.initState();
    context.read<CoinCubit>().useCoin(1);
    _bgPlayer = AudioPlayer();
    _effectPlayer = AudioPlayer();
    _effectDropPlayer = AudioPlayer();

    if (widget.level?.questions != null) {
      words = widget.level!.questions!.map((q) => q.question).toList();
      images = widget.level!.questions!.map((q) => q.qusImage).toList();
    }

    for (var word in words) {
      placedImages[word] = null;
    }

    availableImages = List.from(images)..shuffle();

    _startCountdown();
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
      // Add other headers here if required (e.g., Authorization)
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

  void _stopAllSounds() {
    _bgPlayer.stop();
    _effectPlayer.stop();
    _effectDropPlayer.stop();
  }

  @override
  void dispose() {
    _stopAllSounds();
    super.dispose();
  }

<<<<<<< Updated upstream
  void _showCongratulationsPopup() {
    final hasEnoughQuestions = (widget.preLevels?[widget.levelIndex+1].questions?.length ?? 0) >= 5;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Congratulations!", style: TextStyle(                   fontFamily: AppConstants.commonFont,fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5E3FA0)), textAlign: TextAlign.center),
          content: const Text("You matched all correctly.", textAlign: TextAlign.center, style: TextStyle(                   fontFamily: AppConstants.commonFont,fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            (!hasEnoughQuestions)?SizedBox():TextButton(
              onPressed: () {
                Navigator.pop(context);


                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DragAndLearnApp(levelIndex: widget.levelIndex+1,topicId:widget.topicId,bookId: widget.bookId,level:  widget.preLevels?[widget.levelIndex+1],preLevels: widget.preLevels,),
                  ),
                );
              },
              child: const Text("Next Level", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,   fontFamily: AppConstants.commonFont,)),
            ),
          ],
=======
  bool pauseMusic = false;

  void _showCongratulationsPopup() async{
    final bool hasNextLevel =
        widget.levelIndex + 1 < (widget.preLevels?.length ?? 0);

    final bool nextLevelIsPlayable = hasNextLevel &&
        (widget.preLevels?[widget.levelIndex + 1].questions?.length ?? 0) >= 4;

    final List<Color> playableGradient = [
      const Color(0xFF20c073),
      const Color(0xFF20c073)
    ];
    final List<Color> lockedGradient = [
      Color(0xFF8E44AD), // violet
      Color(0xFF49329A), // base
      Color(0xFFDDA0DD), // soft purple-pink
    ];

    if (await Vibration.hasVibrator() ?? false) {
    Vibration.vibrate(duration: 400);
  }

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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: !nextLevelIsPlayable
                          ? playableGradient
                          : lockedGradient,
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
                    repeat: false,
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

                      // Only show Next Level button if more levels
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
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DragAndLearnApp(
                                  levelIndex: widget.levelIndex + 1,
                                  topicId: widget.topicId,
                                  bookId: widget.bookId,
                                  level:
                                      widget.preLevels?[widget.levelIndex + 1],
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
                ),

                // ---------- Close button ----------
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
>>>>>>> Stashed changes
        );
      },
    );
  }

<<<<<<< Updated upstream
  bool isVolumeMute=true;
=======
  bool isVolumeMute = true;
>>>>>>> Stashed changes
  Map<String?, bool> incorrectDrop = {};

  @override
  Widget build(BuildContext context) {
    double itemSize = 100;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        _stopAllSounds();
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
                    images: images,
                    placedImages: placedImages,
                    availableImages: availableImages,
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

                      int imageIndex = images.indexOf(imagePath);
                      if (wordIndex == imageIndex) {
                        setState(() {
                          placedImages[word] = imagePath;
                          availableImages.remove(imagePath);
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
                      "Drag and place the picture into the correct container",
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
                      itemCount: availableImages.length,
                      itemBuilder: (context, index) {
                        return Draggable<String>(
                          data: availableImages[index],
                          onDragStarted: () => _playEffect('drag.mp3'),
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: itemSize,
                              height: itemSize,
                              child: CachedNetworkImageWidget(
                                  imageUrl:
                                      "https://picturoenglish.com/admin/${availableImages[index] ?? ''}",
                                  fit: BoxFit.cover),
                            ),
                          ),
                          childWhenDragging: SizedBox(
                            width: itemSize,
                            height: itemSize,
                            child: Container(color: Colors.transparent),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImageWidget(
                                  imageUrl:
                                      "https://picturoenglish.com/admin/${availableImages[index] ?? ''}",
                                  fit: BoxFit.cover),
                            ),
                          ),
                        );
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
  final List<String?> images;
  final Map<String?, String?> placedImages;
  final List<String?> availableImages;
  final Map<String?, bool> incorrectDrop;
  final double itemSize;
  final Function(String imagePath, int wordIndex, String? word) onAccept;

  const ImageWordMatchGrid({
    super.key,
    required this.words,
    required this.images,
    required this.placedImages,
    required this.availableImages,
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
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isIncorrect ? Colors.red : Color(0xFFCBBCFF),
                    width: 2,
                  ),
                ),
                padding: EdgeInsets.all(5),
                alignment: Alignment.center,
                child: placedImages[word] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImageWidget(
                          imageUrl:
                              "https://picturoenglish.com/admin/${placedImages[word]!}",
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
<<<<<<< Updated upstream
                  word ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'YourFont',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF49329A),
                  ),
                ),
=======
                        word ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF49329A),
                        ),
                      ),
>>>>>>> Stashed changes
              );
            },
          );
        },
      ),
    );
  }
}
