import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/config/api_key_config.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/responses/unified_plan_info.dart';
import 'package:picturo_app/screens/chatbotmessagelayout%20.dart';
import 'package:picturo_app/screens/premium_plans_screen.dart';
import 'package:picturo_app/services/chatbotapiservice.dart';
import 'package:picturo_app/services/google_translator_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../cubits/get_coins_cubit/coins_cubit.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  Set<String> _mutedMessages = {};
  late ChatBotApiService _apiService;
  bool _isLoading = false;
  bool _isAudioMuted = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late GoogleTranslatorService _translator;

  String? selectedScenario;
  bool _hasEnoughPrompts = true;
  String _selectedLanguage = 'en';
  int _remainingConversations = 0;
  String _planType = 'free';
  bool _planActive = false;
  bool _isLoadingPlanInfo = false;
  bool _forceExpired = false;

  final Map<String, String> _availableLanguages = {
    'en': 'English',
    'ta': 'Tamil',
    'ml': 'Malayalam',
    'te': 'Telugu',
    'hi': 'Hindi',
  };

  @override
  void initState() {
    super.initState();
    _translator =
        GoogleTranslatorService('AIzaSyDn1WqfWC2gG6zck-kAPs2kswqdugsC2yI');
    _initializeApiService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeMessage();
      _loadUserPlanInfo();
    });

    _messageController.addListener(() {
      setState(() {});
    });
  }

  // New method to load initial plan info
  Future<void> _loadInitialPlanInfo() async {
    try {
      setState(() {
        _isLoadingPlanInfo = true;
      });

      final prefs = await SharedPreferences.getInstance();
      // Use the same approach as in _sendMessage
      final currentUserId =
          prefs.getString('user_id') ?? prefs.getInt('user_id')?.toString();

      print('Loading initial plan info for user: $currentUserId');

      if (currentUserId != null && currentUserId.isNotEmpty) {
        final userId = currentUserId;
        if (userId != null) {
          await _fetchPlanInfo(userId);
        } else {
          print('Invalid user ID format: $currentUserId');
          _updatePlanInfoBasedOnInitialState();
        }
      } else {
        print('No user ID found in SharedPreferences');
        _updatePlanInfoBasedOnInitialState();
      }
    } catch (e) {
      print('Error loading initial plan info: $e');
      // Set default values if API fails
      _updatePlanInfoBasedOnInitialState();
    } finally {
      setState(() {
        _isLoadingPlanInfo = false;
      });
    }
  }

  Future<void> _fetchPlanInfo(String userId) async {
    try {
      print('Fetching plan info for user ID: $userId');

      final planInfoResponse =
          await _apiService.getChatBotPlanInfo(userId: userId);

      print('Plan info response status: ${planInfoResponse.status}');
      print('Number of plan info items: ${planInfoResponse.planInfo.length}');

      if (planInfoResponse.planInfo.isNotEmpty) {
        final planInfo = planInfoResponse.planInfo.first;
        print('Plan info details:');
        print(
            '  - estimatedConversationsLeft: ${planInfo.estimatedConversationsLeft}');
        print('  - tokensRemaining: ${planInfo.tokensRemaining}');
        print('  - planType: ${planInfo.planType}');
        print('  - planActive: ${planInfo.planActive}');

        final unifiedPlanInfo = UnifiedPlanInfo.fromChatBotPlanInfo(planInfo);
        _updatePlanInfo(unifiedPlanInfo);
      } else {
        print('No plan info found in response - user has no active plan');
        _updatePlanInfoForNoPlan();
      }
    } catch (e) {
      print('Error fetching plan info: $e');
      // Don't update state on error to preserve current values
      print('Preserving current plan info due to error');
    }
  }

  void _updatePlanInfoForNoPlan() {
    setState(() {
      _remainingConversations = 0;
      _planType = 'free';
      _planActive = false;
      _hasEnoughPrompts = false;

      print('No Plan - Setting to 0 conversations');
      print('  - Remaining Conversations: $_remainingConversations');
      print('  - Plan Type: $_planType');
      print('  - Plan Active: $_planActive');
      print('  - Has Enough Prompts: $_hasEnoughPrompts');
    });
  }

  void _updatePlanInfoBasedOnInitialState() {
    setState(() {
      _remainingConversations = 0; // Changed from 10 to 0
      _planType = 'free';
      _planActive = false; // Changed from true to false
      _hasEnoughPrompts = _remainingConversations > 0;

      print('Initial state - No plan info available');
    });
  }

  void _updatePlanInfo(UnifiedPlanInfo planInfo) {
    if (_forceExpired) {
      print('Ignoring PHP plan response due to known 403 chat expiration');
      return;
    }

    setState(() {
      // Use the actual values from API
      _remainingConversations = planInfo.estimatedConversationsLeft;
      _planType = planInfo.planType;
      _planActive = planInfo.planActive;

      // Client-side expiration check based on planEndDate
      if (planInfo.planEndDate.isNotEmpty) {
        try {
          final DateTime endDate = DateTime.parse(planInfo.planEndDate);
          if (DateTime.now().isAfter(endDate)) {
            print(
                'Client-side check: Plan expired on $endDate. Overriding to inactive.');
            _planActive = false;
            _remainingConversations = 0;
            _forceExpired = true;
          }
        } catch (e) {
          print('Error parsing plan_end_date: $e');
        }
      }

      print('Raw Plan Info:');
      print('  - Plan Type: ${planInfo.planType}');
      print('  - Plan Active: $_planActive'); // Reflect local override
      print(
          '  - Estimated Conversations Left: ${planInfo.estimatedConversationsLeft}');

      // Check if plan is 3M ₹250 for unlimited prompts
      final isUnlimitedPlan =
          planInfo.planType.toLowerCase().contains('3m ₹250');

      print('  - Is Unlimited Plan: $isUnlimitedPlan');

      if (_planActive && isUnlimitedPlan) {
        // For unlimited active plan
        _hasEnoughPrompts = true;
        _remainingConversations =
            99999; // Use a high number to represent unlimited
        print('  - Setting as UNLIMITED plan');
      } else if (_planActive) {
        // For other active premium plans
        _hasEnoughPrompts = _remainingConversations > 0;
        print('  - Setting as LIMITED premium plan');
      } else {
        // For inactive or free plans
        _hasEnoughPrompts = _remainingConversations > 0;
        print('  - Setting as INACTIVE/FREE plan');
      }

      print('Final State:');
      print('  - Remaining Conversations: $_remainingConversations');
      print('  - Plan Type: $_planType');
      print('  - Plan Active: $_planActive');
      print('  - Has Enough Prompts: $_hasEnoughPrompts');
    });
  }

  Future<void> _loadUserPlanInfo() async {
    try {
      setState(() {
        _isLoadingPlanInfo = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      if (currentUserId != null && currentUserId.isNotEmpty) {
        await _fetchPlanInfo(currentUserId);
      } else {
        print('No user ID found, using default state');
        _updatePlanInfoForNoPlan();
      }
    } catch (e) {
      print('Error in _loadUserPlanInfo: $e');
      // Don't reset to no plan on error - keep current state
    } finally {
      setState(() {
        _isLoadingPlanInfo = false;
      });
    }
  }

  void _showNoRemainingPromptsDialog(BuildContext context) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 300);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) {
        final size = MediaQuery.of(context).size;

        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/lottie/nodata.json',
                      width: size.width * 0.4,
                      height: size.width * 0.4,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Chat Prompts Remaining',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins Medium',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF49329A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You have used all your daily chatbot prompts.\n'
                      'Please upgrade your plan or wait until tomorrow.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins Regular',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(fontFamily: 'Poppins Medium'),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PremiumPlansScreen(
                                    isChatBot: true, isCall: false),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF49329A),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Upgrade Plan',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins Medium'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initializeApiService() async {
    _apiService = await ChatBotApiService.create();
  }

  void _showWelcomeMessage() async {
    const welcomeMessage =
        "Welcome to Picturo! I'm your AI English learning buddy. Let's begin!";

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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String base64Audio) async {
    if (_isAudioMuted || base64Audio.isEmpty) return;

    try {
      await _audioPlayer.stop();

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');

      await file.writeAsBytes(base64Decode(base64Audio));
      await _audioPlayer.setFilePath(file.path);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();

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

  String _validateLanguageCode(String code) {
    // Map any incorrect codes to proper ones
    final Map<String, String> codeMapping = {
      'tam': 'ta', // if Tamil is stored as 'tam'
      'malayalam': 'ml', // if Malayalam is stored as 'mal'
      'tel': 'te', // if Telugu is stored as 'tel'
      'hin': 'hi', // if Hindi is stored as 'hin'
    };

    return codeMapping[code] ?? code;
  }

  Future _sendMessage({required String scenario}) async {
    final message = _messageController.text.trim();

    if (!_planActive) {
      _showNoRemainingPromptsDialog(context);
      return;
    }

    if (!_hasEnoughPrompts) {
      _showNoRemainingPromptsDialog(context);
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userLanguage = prefs.getString('selectedLanguage') ?? "";
    userLanguage = _validateLanguageCode(userLanguage);
    final currentUserId = prefs.getString('user_id');

    setState(() {
      _messages.add({
        'message': message,
        'isMe': true,
        'timestamp': _getCurrentTime(),
      });
      _isLoading = true;
    });
    _scrollToBottom();
    _messageController.clear();

    try {
      final response = await _apiService
          .getChatbotResponse(
            message: message,
            language: userLanguage,
            scenario: scenario,
          )
          .timeout(const Duration(seconds: 30));

      // Always refresh plan info after sending a message
      if (currentUserId != null && currentUserId.isNotEmpty) {
        await _fetchPlanInfo(currentUserId);
      }

      String botMessage = (response.error != null && response.error!.isNotEmpty)
          ? response.error!
          : (response.response.isNotEmpty
              ? response.response
              : "I didn't get that. Could you try again?");

      // Final bulletproof check: if the output text says 'expired' or similar from the backend, zero out the state.
      if ((response.error != null && response.error!.isNotEmpty) ||
          botMessage.toLowerCase().contains('expired')) {
        setState(() {
          _planActive = false;
          _hasEnoughPrompts = false;
          _remainingConversations = 0;
          _forceExpired = true;
        });
      }

      if (userLanguage != 'en') {
        try {
          final translated = await _translator.translate(
            text: botMessage,
            targetLanguage: userLanguage,
          );
          botMessage = translated;
        } catch (e) {
          print("Google Translation error: $e");
        }
      }

      botMessage = botMessage
          .replaceAll(RegExp(r'-{2,}'), '')
          .replaceAll(
              RegExp(
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
                  unicode: true),
              '')
          .trim();

      setState(() {
        _messages.add({
          'message': botMessage,
          'isMe': false,
          'timestamp': _getCurrentTime(),
          'audioBase64': '',
          'translation': {},
        });
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _sendMessage: $e');
      setState(() {
        _messages.add({
          'message': "Sorry, something went wrong. Please try again.",
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

  Future<void> _refreshPlanInfo() async {
    try {
      setState(() {
        _isLoadingPlanInfo = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      print('Refreshing plan info for user: $currentUserId');

      if (currentUserId != null && currentUserId.isNotEmpty) {
        final userId = currentUserId;
        if (userId != null) {
          await _fetchPlanInfo(userId);
        } else {
          print('Invalid user ID format: $currentUserId');
        }
      } else {
        print('No user ID found in SharedPreferences');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan info updated'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error refreshing plan info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update plan info'),
          duration: Duration(seconds: 1),
        ),
      );
    } finally {
      setState(() {
        _isLoadingPlanInfo = false;
      });
    }
  }

  final FlutterTts flutterTts = FlutterTts();

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("ta-IN");
    await flutterTts.setSpeechRate(0.5);
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
    await flutterTts.stop();
  }

  void _toggleMute(String message) {
    setState(() {
      if (_isAudioMuted == false) {
        speak(message);
      } else {
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
      final messageWithAudio = _messages.firstWhere(
        (msg) => msg['message'] == message && msg['audioBase64'] != null,
        orElse: () => {},
      );
      if (messageWithAudio.isNotEmpty &&
          messageWithAudio['audioBase64'] != null) {
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

  String _getPromptText() {
    if (_forceExpired) {
      return 'No prompts available';
    }

    final isUnlimitedPlan = _planType.toLowerCase().contains('3m ₹250');

    print(
        'getPromptText - Plan Type: $_planType, Unlimited: $isUnlimitedPlan, Active: $_planActive');

    if (_planActive && isUnlimitedPlan) {
      return 'Unlimited prompts';
    } else if (_planActive) {
      return '$_remainingConversations prompts remaining';
    } else if (_remainingConversations > 0) {
      return '$_remainingConversations free prompts left';
    } else {
      return 'No prompts available';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return SafeArea(
      child: Scaffold(
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
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Image.asset('assets/ai_avatar.png', scale: 10),
                      // if (_planActive &&
                      //     _planType.toLowerCase().contains('3m ₹250'))
                      //   Positioned(
                      //     top: -5,
                      //     right: -35,
                      //     child: Container(
                      //       padding:
                      //           EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      //       decoration: BoxDecoration(
                      //         color: Colors.red,
                      //         borderRadius: BorderRadius.circular(10),
                      //       ),
                      //       constraints: BoxConstraints(
                      //         minWidth: 20,
                      //         minHeight: 20,
                      //       ),
                      //       child: Text(
                      //         'Unlimited',
                      //         style: TextStyle(
                      //           color: Colors.white,
                      //           fontSize: 10,
                      //           fontWeight: FontWeight.bold,
                      //           fontFamily: 'Poppins Regular',
                      //         ),
                      //         textAlign: TextAlign.center,
                      //       ),
                      //     ),
                      //   )
                      // else if (_remainingConversations > 0 && _planActive)
                      //   Positioned(
                      //     top: 0,
                      //     right: 0,
                      //     child: Container(
                      //       padding:
                      //           EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      //       decoration: BoxDecoration(
                      //         color: Colors.red,
                      //         borderRadius: BorderRadius.circular(10),
                      //       ),
                      //       constraints: BoxConstraints(
                      //         minWidth: 20,
                      //         minHeight: 20,
                      //       ),
                      //       child: Text(
                      //         '$_remainingConversations',
                      //         style: TextStyle(
                      //           color: Colors.white,
                      //           fontSize: 10,
                      //           fontWeight: FontWeight.bold,
                      //           fontFamily: 'Poppins Regular',
                      //         ),
                      //         textAlign: TextAlign.center,
                      //       ),
                      //     ),
                      //   ),
                      // if (_isLoadingPlanInfo)
                      //   Positioned(
                      //     top: 0,
                      //     right: 0,
                      //     child: Container(
                      //       padding: EdgeInsets.all(4),
                      //       decoration: BoxDecoration(
                      //         color: Colors.orange,
                      //         borderRadius: BorderRadius.circular(10),
                      //       ),
                      //       child: SizedBox(
                      //         width: 12,
                      //         height: 12,
                      //         child: CircularProgressIndicator(
                      //           strokeWidth: 2,
                      //           valueColor:
                      //               AlwaysStoppedAnimation<Color>(Colors.white),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
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
                            fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getPromptText(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontFamily: 'Poppins Regular',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(width: 25),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _isLoadingPlanInfo ? null : _refreshPlanInfo,
                tooltip: 'Refresh plan info',
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
                          isMeChatting: message['isMe'],
                          messageBody: message['message'],
                          timestamp: message['timestamp'],
                          isMuted: !message['isMe'] && _isAudioMuted,
                          onMuteToggle: (String message) {
                            _toggleMute(message);
                          },
                          userSelectedLanguage: _selectedLanguage,
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        child: GestureDetector(
                          onTap: _messageController.text.isNotEmpty
                              ? () async {
                                  _sendMessage(
                                      scenario: selectedScenario ?? "");
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
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
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
            child: Text(
              question,
              style: TextStyle(fontSize: 12),
            ),
          );
        }).toList());
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
              fontWeight: FontWeight.bold),
        );
      },
    );
  }
}
