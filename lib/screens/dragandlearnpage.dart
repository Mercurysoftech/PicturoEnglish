import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/screens/dragandlearntopics.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../cubits/drag_and_learn_cubit/drag_and_learn_cubit.dart';
import '../models/dragand_learn_model.dart';
import '../utils/common_file.dart';

class DragAndLearnApp extends StatefulWidget {
  const DragAndLearnApp({super.key, required this.level,required this.bookId,required this.topicId, required this.levelIndex,required this.preLevels});
  final Levels? level;
  final int? bookId;
  final int? topicId;
  final int levelIndex;
  final  List<Levels>? preLevels;

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

  bool showCountdown = true;
  int countdown = 3;

  @override
  void initState() {

    super.initState();

    _bgPlayer = AudioPlayer();
    _effectPlayer = AudioPlayer();

    if (widget.level?.questions != null) {
      words = widget.level!.questions!.map((q) => q.question).toList();
      images = widget.level!.questions!.map((q) => q.qusImage).toList();
    }

    for (var word in words) {
      placedImages[word] = null;
    }
    availableImages = List.from(images);

    _startCountdown();
  }
  Future<void> markQuestionAsRead({
    required int bookId,
    required int topicId,
    required int questionId,
    required bool isRead,
  }) async {

    final url = Uri.parse('https://picturoenglish.com/api/dragandlearn_qusupdate.php');
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");

    final headers = {
      "Authorization": "Bearer $token",
      'Content-Type': 'application/json',
      // Add other headers here if required (e.g., Authorization)
    };

    final body = jsonEncode({
      'book_id': bookId,
      'topic_id': 1,
      'question_id': questionId,
      'is_read': isRead,
    });

    try {

      final response = await http.post(url, headers: headers, body: body);
      print("ksdjcnskjdcksjncskdjc ${body} ${response.body}");

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
    final url = Uri.parse('https://picturoenglish.com/api/markleveldragandlearn.php');
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");
    final headers = {
      "Authorization": "Bearer $token",
      'Content-Type': 'application/json',
      // Add any other headers like Authorization if needed
    };

    final body = jsonEncode({
      'book_id': bookId,
      'topic_id': 1,
      'level': level,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      print("ksdjcnskjdcksjncskdjc Level ${body} ${response.body}");
      if (response.statusCode == 200) {
        print('✅ Level marked as completed: ${response.body}');
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
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgPlayer.play(AssetSource('audio/bg_music.mp3'));
  }

  void _playEffect(String fileName) async {
    await _effectPlayer.play(AssetSource('audio/$fileName'));
  }

  void _stopAllSounds() {
    _bgPlayer.stop();
    _effectPlayer.stop();
  }

  @override
  void dispose() {
    _stopAllSounds();
    super.dispose();
  }

  void _showCongratulationsPopup() {
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
            TextButton(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double itemSize = 100;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        _stopAllSounds();
        context.read<DragLearnCubit>().fetchDragLearnData(bookId: widget.bookId??0,isLoading: true);
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
                  context.read<DragLearnCubit>().fetchDragLearnData(bookId: widget.bookId??0,isLoading: true);
                  Navigator.pop(context);
                },
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Drag and Learn',
                style: TextStyle(                   fontFamily: AppConstants.commonFont,color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            // shape: RoundedRectangleBorder(
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

                   Text("Level ${widget.levelIndex+1}", style: TextStyle(                   fontFamily: AppConstants.commonFont,fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
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

                      itemCount: words.length,
                      itemBuilder: (context, index) {
                        String? word = words[index];
                        return DragTarget<String>(
                          onWillAcceptWithDetails: (data) => true,
                          onAccept: (imagePath) async{
                            int wordIndex = words.indexOf(word);
                            print("sldkcmlskmdclskmc ${widget.level?.questions?[wordIndex].question}");
                           await markQuestionAsRead(bookId: widget.bookId??0, topicId: widget.topicId??0, questionId: widget.level?.questions?[wordIndex].id??0, isRead: true);
                            _playEffect('drop.mp3');

                            int imageIndex = images.indexOf(imagePath);
                            if (wordIndex == imageIndex) {
                              setState(() {
                                placedImages[word] = imagePath;
                                availableImages.remove(imagePath);
                              });
                            }
                            if (placedImages.values.every((value) => value != null)) {
                              await markLevelAsCompleted(bookId: widget.bookId??0, topicId: widget.topicId??0, level: widget.level?.level??0);
                              await Future.delayed(Duration(milliseconds: 300), _showCongratulationsPopup);
                            }
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color(0xFFCBBCFF), width: 1),
                              ),padding: EdgeInsets.all(5),
                              
                              alignment: Alignment.center,
                              child: placedImages[word] != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  "https://picturoenglish.com/admin/${placedImages[word]!}",
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Text(word ?? '',
                                    textAlign: TextAlign.center,

                                    style: TextStyle(
                                    fontFamily: AppConstants.commonFont,fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF49329A)),
                                                                ),
                            );
                          },
                        );
                      },
                    ),
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
                      style: TextStyle(                   fontFamily: AppConstants.commonFont,fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
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
                              child: Image.network("https://picturoenglish.com/admin/${availableImages[index] ?? ''}", fit: BoxFit.cover),
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
                              child: Image.network("https://picturoenglish.com/admin/${availableImages[index] ?? ''}", fit: BoxFit.cover),
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
