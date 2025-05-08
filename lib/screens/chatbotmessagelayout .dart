import 'package:flutter/material.dart';

class ChatBotMessageLayout extends StatelessWidget {
  final bool isMeChatting;
  final String messageBody;
  final String timestamp;
  final bool isMuted;
  final bool isError;
  final VoidCallback? onMuteToggle;
  

  const ChatBotMessageLayout({
    super.key,
    required this.isMeChatting,
    required this.messageBody,
    required this.timestamp,
    required this.isMuted,
    this.isError = false, 
    this.onMuteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMeChatting ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: isMeChatting ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: isMeChatting
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
                    color:  isError 
                        ? Colors.red.withOpacity(0.1)
                        : isMeChatting 
                            ? const Color(0xFF49329A) 
                            : null,
                    gradient: isError || isMeChatting
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
                      color:isError ? Colors.red : 
                      isMeChatting ? Colors.transparent : const Color(0xFFC9BAFF),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    messageBody,
                    style: TextStyle(
                      fontFamily: 'Poppins Regular',
                      fontSize: 15,
                      color: isMeChatting ? Colors.white : const Color(0xFF0D082C),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    timestamp,
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
          
          // Show mute icon only for AI replies (not for user messages)
          if (!isMeChatting) 
            if (onMuteToggle != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: GestureDetector(
                onTap: onMuteToggle,
                child: Icon(
                  isMuted ? Icons.volume_off : Icons.volume_up,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }
}