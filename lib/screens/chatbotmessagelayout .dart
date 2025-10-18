import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picturo_app/config/api_key_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picturo_app/services/google_translator_service.dart';

class ChatBotMessageLayout extends StatefulWidget {
  final bool isMeChatting;
  final String messageBody;
  final String timestamp;
  final int index;
  final bool isMuted;
  final bool isError;
  final Function(String message) onMuteToggle;
  final String userSelectedLanguage;

  const ChatBotMessageLayout({
    super.key,
    required this.isMeChatting,
    required this.messageBody,
    required this.timestamp,
    required this.index,
    required this.isMuted,
    this.isError = false,
    required this.onMuteToggle,
    required this.userSelectedLanguage,
  });

  @override
  State<ChatBotMessageLayout> createState() => _ChatBotMessageLayoutState();
}

class _ChatBotMessageLayoutState extends State<ChatBotMessageLayout> {
  String selectedLanguageCode = "en"; // default to English
  String translatedMessage = "";
  bool isTranslating = false;
  bool hasTranslationError = false;
  final String welcomeMessage =
      "Welcome to Picturo! I'm your AI English learning buddy. Let's begin!";

  late GoogleTranslatorService _translator;

  Map<String, String> languageMap = {
    "en": "English",
    "ta": "Tamil",
    "ml": "Malayalam",
    "te": "Telugu",
    "hi": "Hindi",
  };

  @override
  void initState() {
    super.initState();
    _translator = GoogleTranslatorService('AIzaSyDn1WqfWC2gG6zck-kAPs2kswqdugsC2yI');

    selectedLanguageCode = _validateLanguageCode(widget.userSelectedLanguage);
  }

  String _validateLanguageCode(String code) {
    // Normalize the code
    final normalizedCode = code.toLowerCase().trim();

    final Map<String, String> codeMapping = {
      'tamil': 'ta',
      'tam': 'ta',
      'malayalam': 'ml',
      'mal': 'ml',
      'telugu': 'te',
      'tel': 'te',
      'hindi': 'hi',
      'hin': 'hi',
      'english': 'en',
      'eng': 'en',
    };

    // Check if it's already a valid code
    if (languageMap.containsKey(normalizedCode)) {
      return normalizedCode;
    }

    // Check mapping
    if (codeMapping.containsKey(normalizedCode)) {
      return codeMapping[normalizedCode]!;
    }

    // Default to English for unsupported languages
    print('Unsupported language code: $code, defaulting to English');
    return "en";
  }

  Future<void> _translateMessage() async {
    if (widget.messageBody.isEmpty) {
      setState(() {
        translatedMessage = "No text to translate";
        isTranslating = false;
      });
      return;
    }

    // Don't translate if already in English or if it's the welcome message
    if (selectedLanguageCode == "en" || widget.messageBody == welcomeMessage) {
      setState(() {
        translatedMessage = widget.messageBody;
        isTranslating = false;
      });
      return;
    }

    setState(() {
      isTranslating = true;
      hasTranslationError = false;
      translatedMessage = "";
    });

    try {
      print('=== Translation Debug Info ===');
      print('Target language: $selectedLanguageCode');
      print('Language name: ${_getLanguageName(selectedLanguageCode)}');
      print('Original text: ${widget.messageBody}');
      print('Text length: ${widget.messageBody.length}');

      // Validate API key
      if (ApiConfig.googleTranslateApiKey.isEmpty) {
        throw Exception('Google Translate API key is not configured');
      }

      // Validate language support
      if (!languageMap.containsKey(selectedLanguageCode)) {
        throw Exception(
            'Language $selectedLanguageCode is not supported. Available: ${languageMap.keys.join(', ')}');
      }

      // Use Google Translator Service
      final translation = await _translator.translate(
        text: widget.messageBody,
        targetLanguage: selectedLanguageCode,
      );

      print('Translation successful: $translation');

      if (translation.isEmpty) {
        throw Exception('Received empty translation');
      }

      setState(() {
        translatedMessage = translation;
        isTranslating = false;
      });
    } catch (e) {
      print('=== Translation Error Details ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');

      setState(() {
        translatedMessage =
            "Translation failed: ${e.toString().replaceFirst('Exception: ', '')}";
        isTranslating = false;
        hasTranslationError = true;
      });
    }
  }

  void _onLanguageSelected(String code) {
    final validatedCode = _validateLanguageCode(code);

    if (validatedCode == selectedLanguageCode && translatedMessage.isNotEmpty) {
      return;
    }

    setState(() {
      selectedLanguageCode = validatedCode;
      translatedMessage = "";
      hasTranslationError = false;
    });

    // Only translate if not English and not welcome message
    if (validatedCode != "en" && widget.messageBody != welcomeMessage) {
      _translateMessage();
    } else if (validatedCode == "en") {
      // If English is selected, show original message
      setState(() {
        translatedMessage = widget.messageBody;
      });
    }
  }

  String _getLanguageName(String code) {
    return languageMap[code] ?? "English";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: widget.isMeChatting
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: widget.isMeChatting
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: widget.isMeChatting
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          )
                        : const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                    color: widget.isError
                        ? Colors.red.withOpacity(0.1)
                        : widget.isMeChatting
                            ? const Color(0xFF49329A)
                            : null,
                    gradient: widget.isError || widget.isMeChatting
                        ? null
                        : const LinearGradient(
                            colors: [
                              Color(0xFFEAE4FF),
                              Color(0xFFE0F7FF),
                              Color(0xFFFEF0D3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: Border.all(
                      color: widget.isError
                          ? Colors.red
                          : widget.isMeChatting
                              ? Colors.transparent
                              : const Color(0xFFC9BAFF),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.messageBody,
                        style: TextStyle(
                          fontFamily: 'Poppins Regular',
                          fontSize: 15,
                          color: widget.isMeChatting
                              ? Colors.white
                              : const Color(0xFF0D082C),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (selectedLanguageCode != "en" &&
                          widget.messageBody != welcomeMessage)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: Colors.grey),
                            Row(
                              children: [
                                Text(
                                  "Translation (${_getLanguageName(selectedLanguageCode)})",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                if (hasTranslationError)
                                  Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 14,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (isTranslating)
                              Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Translating...",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              )
                            else
                              Stack(
                                children: [
                                  Text(
                                    translatedMessage,
                                    style: TextStyle(
                                      fontFamily: 'Poppins Regular',
                                      fontSize: 15,
                                      color: widget.isMeChatting
                                          ? Colors.white
                                          : const Color(0xFF0D082C),
                                    ),
                                  ),
                                  if (!hasTranslationError &&
                                      translatedMessage.isNotEmpty)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          widget
                                              .onMuteToggle(translatedMessage);
                                        },
                                        child: Icon(
                                          widget.isMuted
                                              ? Icons.volume_off
                                              : Icons.volume_up,
                                          size: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.timestamp,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins Regular',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Controls
          if (!widget.isMeChatting)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      widget.onMuteToggle(widget.messageBody);
                    },
                    child: Icon(
                      widget.isMuted ? Icons.volume_off : Icons.volume_up,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      Clipboard.setData(
                          ClipboardData(text: widget.messageBody));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Copied to clipboard!")),
                      );
                    },
                    child: Icon(Icons.copy, size: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      _showLanguageDialog(context);
                    },
                    child: Icon(Icons.translate,
                        size: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userLang = prefs.getString('selectedLanguage') ?? "en";
    final validatedLang = _validateLanguageCode(userLang);
    final userLangName = _getLanguageName(validatedLang);

    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Translate to $userLangName?",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel",
                          style: TextStyle(fontFamily: 'Poppins')),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, validatedLang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF49329A),
                      ),
                      child: Text("Translate",
                          style: TextStyle(
                              fontFamily: 'Poppins', color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      _onLanguageSelected(selected);
    }
  }
}
