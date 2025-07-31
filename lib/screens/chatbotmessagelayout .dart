import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:translator/translator.dart';

class ChatBotMessageLayout extends StatefulWidget {
  final bool isMeChatting;
  final String messageBody;
  final String timestamp;
  final int index;
  final bool isMuted;
  final bool isError;
  final Function(String message) onMuteToggle;

  const ChatBotMessageLayout({
    super.key,
    required this.isMeChatting,
    required this.messageBody,
    required this.timestamp,
    required this.index,
    required this.isMuted,
    this.isError = false,
    required this.onMuteToggle,
  });

  @override
  State<ChatBotMessageLayout> createState() => _ChatBotMessageLayoutState();
}

class _ChatBotMessageLayoutState extends State<ChatBotMessageLayout> {
  String selectedLanguageCode = "en"; // default to English
  String translatedMessage = "";
  bool isTranslating = false;
  final String welcomeMessage = "Welcome to Picturo! I'm your AI English learning buddy. Let's begin!";

  final translator = GoogleTranslator();

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
    // Translate if not English
    if (selectedLanguageCode != "en") {
      _translateMessage();
    }
  }

  Future<void> _translateMessage() async {
    setState(() {
      isTranslating = true;
    });

    try {
      var translation = await translator.translate(
        widget.messageBody,
        to: selectedLanguageCode,
      );
      setState(() {
        translatedMessage = translation.text;
        isTranslating = false;
      });
    } catch (e) {
      setState(() {
        translatedMessage = "Translation failed";
        isTranslating = false;
      });
    }
  }

  void _onLanguageSelected(String code) {
    setState(() {
      selectedLanguageCode = code;
      translatedMessage = "";
    });

    if (code != "en") {
      _translateMessage();
    }
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
                            Text(
                              "Translation",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            if (isTranslating)
                              const Text("Translating...",
                                  style: TextStyle(fontSize: 14))
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
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        widget.onMuteToggle(translatedMessage);
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
                    child:
                    Icon(Icons.language, size: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) async {
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
                const Text(
                  "Choose Language",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: languageMap.entries
                      .map((entry) => _languageOption(entry.value, entry.key))
                      .toList(),
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

  Widget _languageOption(String label, String code) {
    return InkWell(
      onTap: () {
        Navigator.pop(context, code);
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF49329A),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
