import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/providers/remaining_bot_calls_provider';
import 'package:picturo_app/screens/chatbotmessagelayout%20.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/screens/premium_plans_screen.dart';
import 'package:picturo_app/screens/threedotloading.dart';
import 'package:picturo_app/screens/widgets/commons.dart';
import 'package:picturo_app/services/chatbotapiservice.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../cubits/get_coins_cubit/coins_cubit.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  Set<String> _mutedMessages = {};
  late ChatBotApiService _apiService;
  bool _isLoading = false;
  //late stt.SpeechToText _speech;
  //bool _isListening = false;
  // late AnimationController _scaleController;
  // late Animation<double> _scaleAnimation;
  // late AnimationController _colorController;
  // late Animation<Color?> _colorAnimation;
  //bool _isRecording = false;
  bool _isAudioMuted = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? selectedScenario;
  bool _hasEnoughPrompts = true;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
    //_speech = stt.SpeechToText();
    //_initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeMessage();
       _checkRemainingPrompts();
    });

    // _scaleController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(milliseconds: 200),
    // );
    // _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(_scaleController);

    // _colorController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(milliseconds: 200),
    // );
    // _colorAnimation = ColorTween(
    //   begin: const Color(0xFF49329A),
    //   end: Colors.red,
    // ).animate(_colorController);

    _messageController.addListener(() {
      setState(() {});        
    });
    
  }

  void _checkRemainingPrompts() {
    final botCallsProvider = context.read<RemainingBotCallsProvider>();
    setState(() {
      _hasEnoughPrompts = botCallsProvider.dailyRemainingPrompts > 0;
    });
  }

  Future<void> _initializeApiService() async {
    _apiService = await ChatBotApiService.create();
    
  }

  void _showWelcomeMessage() async {
    const welcomeMessage = "Welcome to Picturo! I'm your AI English learning buddy. Let's begin!";
    
    setState(() {
      _messages.insert(0, {
        'message': welcomeMessage,
        'isMe': false,
        'timestamp': _getCurrentTime(),
      });
    });
    _scrollToBottom();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour % 12;           
    final amPm = now.hour < 12 ? 'AM' : 'PM';            
    final minute = now.minute.toString().padLeft(2, '0');
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute $amPm';
  }

  // void _initSpeech() async {
  //   var status = await Permission.microphone.request();
  //   if (status.isGranted) {
  //     bool available = await _speech.initialize(
  //       onStatus: (status) {
  //         if (status == 'notListening' && _isListening) {
  //           setState(() => _isListening = false);
  //         }
  //       },
  //       onError: (error) => print('Error: $error'),
  //     );
  //   } else {
  //   }
  // }

  // void _startListening() async {
  //   if (!_isListening) {
  //     bool available = await _speech.initialize();
  //     if (available) {
  //       setState(() {
  //         _isListening = true;
  //         _isRecording = true;
  //       });
  //       _scaleController.forward();
  //       _colorController.forward();
  //       _speech.listen(
  //         onResult: (result) {
  //           setState(() {
  //             _messageController.text = result.recognizedWords;
  //             _messageController.selection = TextSelection.fromPosition(
  //               TextPosition(offset: _messageController.text.length),
  //             );
  //           });
  //         },
  //       );
  //     }
  //   }
  // }

  // void _stopListening() {
  //   if (_isListening) {
  //     _speech.stop();
  //     setState(() {
  //       _isListening = false;
  //       _isRecording = false;
  //     });
                
  //     if (_messageController.text.isEmpty) {
  //       _scaleController.reverse();
  //       _colorController.reverse();
  //     }
  //   }
  // }

  @override
  void dispose() {
    //_scaleController.dispose();
    //_colorController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String base64Audio) async {
  if (_isAudioMuted || base64Audio.isEmpty) return;
  
  try {
    // Stop any currently playing audio
    await _audioPlayer.stop();
    
    // Create a temporary file with unique name
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
    
    // Write and play the file
    await file.writeAsBytes(base64Decode(base64Audio));
    await _audioPlayer.setFilePath(file.path);
    await _audioPlayer.setVolume(1.0); // Ensure full volume
    await _audioPlayer.play();

    // Clean up after playback
    _audioPlayer.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        try {
          await file.delete();
        } catch (e) {
          print('Error deleting audio file: $e');
        }
      }
    }, onError: (e) {
      print('Audio playback error: $e');
      file.delete().catchError((_) {});
    });
  } catch (e) {
    print('Error in _playAudio: $e');
  }
}

  Future _sendMessage({required String scenario}) async {
  final message = _messageController.text.trim();
   final botCallsProvider = context.read<RemainingBotCallsProvider>();
  final remainingPrompts = botCallsProvider.dailyRemainingPrompts;

   if (remainingPrompts <= 0) {
      _showNoRemainingPromptsDialog();
      return;
    }


  SharedPreferences prefs = await SharedPreferences.getInstance();
 String userLanguage= prefs.getString('selectedLanguage')??"";
  // if (_isListening) {
  //   _stopListening();
  // }
  
  setState(() {
    //_isRecording = false;
    //_isListening = false;
    _messages.add({
      'message': message,
      'isMe': true,
      'timestamp': _getCurrentTime(),
    });

    _isLoading = true;
  });
  _scrollToBottom();
  _messageController.clear();
  //_scaleController.reverse();
  //_colorController.reverse();

  try {

  botCallsProvider.decrementDailyPrompts();
      _checkRemainingPrompts();

    final response = await _apiService.getChatbotResponse(
      message: message,
      language: userLanguage,
      scenario: scenario,
    ).timeout(const Duration(seconds: 30));

    //context.read<CoinCubit>().useCoin(1);

    String botMessage = response.response.isNotEmpty
        ? response.response
        : "I didn't get that. Could you try again?";
    String? audioBase64 = '';
    botMessage = botMessage
        .replaceAll(RegExp(r'-{2,}'), '')
        .replaceAll(RegExp(
        r'[\u{1F600}-\u{1F64F}'
        r'\u{1F300}-\u{1F5FF}'
        r'\u{1F680}-\u{1F6FF}'
        r'\u{1F1E0}-\u{1F1FF}'
        r'\u{2600}-\u{26FF}'
        r'\u{2700}-\u{27BF}'
        r'\u{1F900}-\u{1F9FF}'
        r'\u{1FA70}-\u{1FAFF}'
        r'\u{200D}'
        r'\u{FE0F}'
        r'\u{1F018}-\u{1F270}'
        r'\u{238C}-\u{2454}'
        r']+',
        unicode: true), '')
        .trim();

    setState(() {
      _messages.add({
        'message': botMessage,
        'isMe': false,
        'timestamp': _getCurrentTime(),
        'audioBase64': '',
        'translation': response.translations,
      });
      _isLoading = false;
    });
  } catch (e) {
    // Show the error from `error` key
    botCallsProvider.updateValues(dailyPrompts: remainingPrompts);
    _checkRemainingPrompts();

    setState(() {
      _messages.add({
        'message': e.toString().replaceFirst("Exception: ", ""),
        'isMe': false,
        'timestamp': _getCurrentTime(),
        'audioBase64': '',
        'translation': {},
      });
      _isLoading = false;
    });
  }
  _scrollToBottom();


}


void _showNoRemainingPromptsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'No Chat Prompts Remaining',
            style: TextStyle(
              fontFamily: 'Poppins Regular',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'You have used all your daily chatbot prompts. '
            'Please upgrade your plan or wait until tomorrow for your prompts to reset.',
            style: TextStyle(fontFamily: 'Poppins Regular'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(fontFamily: 'Poppins Regular'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to premium screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PremiumPlansScreen()),
                );
              },
              child: Text(
                'Upgrade Plan',
                style: TextStyle(
                  color: Color(0xFF49329A),
                  fontFamily: 'Poppins Regular',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }




Future<void> _playAudioWithRetry(String base64Audio, {int retryCount = 3}) async {
  if (_isAudioMuted || base64Audio.isEmpty) return;

  // Validate base64 string
  if (!RegExp(r'^[a-zA-Z0-9+/]+={0,2}$').hasMatch(base64Audio)) {
    print('Invalid base64 string');
    return;
  }

  for (int attempt = 0; attempt < retryCount; attempt++) {
    File? tempFile;
    try {
      // Create temporary directory
      final dir = await getTemporaryDirectory();
      tempFile = File('${dir.path}/chat_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
      
      // Write file with error checking
      final bytes = base64Decode(base64Audio);
      if (bytes.isEmpty) {
        print('Decoded bytes are empty');
        continue;
      }
      
      await tempFile.writeAsBytes(bytes);
      
      // Verify file exists and has content
      if (!(await tempFile.exists())) {
        print('File not created');
        continue;
      }
      
      final fileSize = await tempFile.length();
      if (fileSize == 0) {
        print('Empty file created');
        continue;
      }

      // Setup player
      await _audioPlayer.stop(); // Stop any current playback
      await _audioPlayer.setFilePath(tempFile.path);
      
      // Wait for player to be ready
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();

      // Cleanup after playback completes
      _audioPlayer.playerStateStream.listen((state) async {
        if (state.processingState == ProcessingState.completed && tempFile != null) {
          try {
            await tempFile!.delete();
          } catch (e) {
            print('Error deleting temp file: $e');
          }
        }
      }, onError: (e) {
        print('Player error: $e');
        tempFile?.delete().catchError((_) {});
      });

      return; // Success - exit loop
      
    } catch (e) {
      print('Attempt ${attempt + 1} failed: $e');
      await tempFile?.delete().catchError((_) {});
      
      if (attempt == retryCount - 1) {
        print('Failed after $retryCount attempts');
      } else {
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
  }
}
  final FlutterTts flutterTts = FlutterTts();

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("ta-IN");
    await flutterTts.setSpeechRate(0.5); // adjust speed if needed
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
    flutterTts.setCompletionHandler(() {
      setState(() {
        _isAudioMuted = !_isAudioMuted;
      });

    });

  }
  Future<void> stopSpeaking() async {
    await flutterTts.stop(); // This stops any ongoing speech
  }
  void _toggleMute(String message) {
    setState(() {

      if(_isAudioMuted==false){
        speak(message);
      }else{
        stopSpeaking();
      }
      _isAudioMuted = !_isAudioMuted;
      if (_mutedMessages.contains(message)) {
        _mutedMessages.remove(message);
      } else {
        _mutedMessages.add(message);
      }
    });

    if (_isAudioMuted) {
      _audioPlayer.stop();
    } else {
      // Find the message with audio and play it if available
      final messageWithAudio = _messages.firstWhere(
        (msg) => msg['message'] == message && msg['audioBase64'] != null,
        orElse: () => {},
      );
      if (messageWithAudio.isNotEmpty && messageWithAudio['audioBase64'] != null) {
        _playAudio(messageWithAudio['audioBase64']);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    // _scrollToBottom();

    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Consumer<RemainingBotCallsProvider>(
              builder: (context, botCalls, child) {
                 final remainingPrompts = botCalls.dailyRemainingPrompts;

                return Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset('assets/ai_avatar.png', scale: 10),
                        if (remainingPrompts > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '$remainingPrompts',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins Regular',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chat AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins Regular',
                            fontSize: 18
                          ),
                        ),
                        if (remainingPrompts > 0)
                          Text(
                            '$remainingPrompts prompts left',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Poppins Regular',
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            //CoinBadge(),
            SizedBox(width: 25),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                context.read<RemainingBotCallsProvider>().fetchRemainingBotCalls();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Refreshing prompts...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Refresh prompts',
            ),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
          ),
        ),
      ),
      ),
      body: Container(
        decoration: const BoxDecoration(
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
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    final message = _messages[index];
                    return Align(
                      alignment: message['isMe'] 
                          ? Alignment.centerRight 
                          : Alignment.centerLeft,
                      child: ChatBotMessageLayout(
                        index: index,
                        // translation: message['translation']??{},
                        isMeChatting: message['isMe'],
                        messageBody: message['message'],
                        timestamp: message['timestamp'],
                        isMuted: !message['isMe'] && _isAudioMuted,
                        onMuteToggle: (String message){
                          _toggleMute(message);
                        },
                      ),
                    );
                  } else {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ThinkingText(
                          color: const Color(0xFF49329A),    
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

            // if(_messages.length <=1)
            //   Padding(
            //     padding:  EdgeInsets.only(bottom: ((_messages.length <=1))?22.0:0),
            //     child: ChatBotQuickReplies(
            //       onSend: (message) {
            //         _messageController.text = message;
            //         selectedScenario=message;
            //         _sendMessage(scenario:selectedScenario??"");
            //       },
            //     ),
            //   ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: Padding(
  padding: const EdgeInsets.only(right: 5),
  child: Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(30),
    child: GestureDetector(
      onTap: _messageController.text.isNotEmpty
          ? () async {
              _sendMessage(scenario: selectedScenario ?? "");
              context.read<CoinCubit>().useCoin(1);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF49329A),
          borderRadius: BorderRadius.circular(30),
        ),
        child: SvgPicture.string(
          Svgfiles.sendSvg,
          width: 24,
          height: 24,
        ),
      ),
    ),
  ),
),
                ),
                // onSubmitted: (_) =>  _sendMessage(scenario:selectedScenario??"" ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


class ChatBotQuickReplies extends StatelessWidget {
  final List<String> predefinedQuestions = [
    "Restaurant",
    "Shop",
    "Travel",
    "General",
  ];

  final void Function(String message) onSend;

  ChatBotQuickReplies({super.key, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: predefinedQuestions.map((question) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF49329A).withValues(alpha: .85),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () => onSend(question),
          child: Text(question,style: TextStyle(fontSize: 12),),
        );
      }).toList(),
    );
  }
}
class ThinkingText extends StatefulWidget {
  final Color color;
  const ThinkingText({super.key, this.color = Colors.black});

  @override
  _ThinkingTextState createState() => _ThinkingTextState();
}

class _ThinkingTextState extends State<ThinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
    _dotAnimation = StepTween(begin: 0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotAnimation,
      builder: (context, child) {
        String dots = '.' * _dotAnimation.value;
        return Text(
          "Thinking$dots",
          style: TextStyle(
            color: widget.color,
            fontSize: 16,
            fontFamily: 'Poppins Medium',
            fontWeight: FontWeight.bold
          ),
        );
      },
    );
  }
}
