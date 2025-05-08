import 'package:flutter/material.dart';

class ChatMessageLayout extends StatelessWidget {
  final bool isMeChatting;
  final String messageBody;
  final String? senderName;
  final String timestamp;

  const ChatMessageLayout({
    super.key,
    required this.isMeChatting,
    required this.messageBody,
    this.senderName,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isMeChatting ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Show sender's name only for the other user
          if (!isMeChatting && senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Text(
                senderName!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontFamily: 'Poppins Regular',
                ),
              ),
            ),
          Stack(
            children: [
              Align(
                alignment: isMeChatting ? Alignment.centerRight : Alignment.centerLeft,
                child: IntrinsicWidth( // Dynamically adjusts width based on text length
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65, // Set max width
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: isMeChatting
                          ? BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            )
                          : BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                      color: isMeChatting ? Color(0xFF49329A) : Colors.white,
                    ),
                    margin: const EdgeInsets.only(bottom: 14), // Space for timestamp
                    child: Text(
                      messageBody,
                      style: TextStyle(
                        fontFamily: 'Poppins Regular',
                        fontSize: 15,
                        color: isMeChatting ? Colors.white : Color(0xFF0D082C),
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: isMeChatting ? 0 : null,
                left: isMeChatting ? null : 0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    timestamp,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins Regular',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
