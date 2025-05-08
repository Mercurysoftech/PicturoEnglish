import 'package:flutter/material.dart';


class VoiceCallScreen extends StatefulWidget {
  final int callerId;
  final String callerName;
  final String? callerImage;
  final bool isIncoming;

  const VoiceCallScreen({
    super.key,
    required this.callerId,
    required this.callerName,
    required this.callerImage,
    this.isIncoming = false,
  });

  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool isMuted = false;
  bool isSpeakerOn = false;
  bool isKeypadVisible = false;
  bool showCallControls = true;
  Duration callDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Start a timer to update call duration
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          callDuration += Duration(seconds: 1);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black87,
                  Colors.black,
                ],
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              SizedBox(height: 60),
              // Caller info
              Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(widget.callerImage!),
                  ),
                  SizedBox(height: 20),
                  Text(
                    widget.callerName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.isIncoming ? "Incoming call" : "Calling...",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _formatDuration(callDuration),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              Spacer(),

              // Call controls
              if (showCallControls) ...[
                if (isKeypadVisible) _buildKeypad(),
                if (!isKeypadVisible) _buildCallControls(),
              ],
            ],
          ),

          // Close button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        children: [
          // First row of controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildControlButton(
                icon: isMuted ? Icons.mic_off : Icons.mic,
                label: "Mute",
                isActive: isMuted,
                onPressed: () => setState(() => isMuted = !isMuted),
              ),
              _buildControlButton(
                icon: Icons.dialpad,
                label: "Keypad",
                onPressed: () => setState(() => isKeypadVisible = true),
              ),
              _buildControlButton(
                icon: isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                label: "Speaker",
                isActive: isSpeakerOn,
                onPressed: () => setState(() => isSpeakerOn = !isSpeakerOn),
              ),
            ],
          ),
          SizedBox(height: 40),
          // Second row of controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildControlButton(
                icon: Icons.person_add,
                label: "Add call",
                onPressed: () {},
              ),
              _buildControlButton(
                icon: Icons.videocam,
                label: "Video",
                onPressed: () {},
              ),
              _buildControlButton(
                icon: Icons.record_voice_over,
                label: "Record",
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 60),
          // End call button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.call_end,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.grey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          padding: EdgeInsets.all(15),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 30),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildKeypadButton("1", ""),
              _buildKeypadButton("2", "ABC"),
              _buildKeypadButton("3", "DEF"),
              _buildKeypadButton("4", "GHI"),
              _buildKeypadButton("5", "JKL"),
              _buildKeypadButton("6", "MNO"),
              _buildKeypadButton("7", "PQRS"),
              _buildKeypadButton("8", "TUV"),
              _buildKeypadButton("9", "WXYZ"),
              _buildKeypadButton("*", ""),
              _buildKeypadButton("0", "+"),
              _buildKeypadButton("#", ""),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildControlButton(
                icon: Icons.arrow_back,
                label: "Back",
                onPressed: () => setState(() => isKeypadVisible = false),
              ),
              _buildControlButton(
                icon: Icons.call,
                label: "Call",
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.call_end,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String number, String letters) {
    return GestureDetector(
      onTap: () {
        // Handle keypad press
        print("Pressed: $number");
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Example usage:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => VoiceCallScreen(
//       callerName: "John Doe",
//       callerImage: "https://example.com/profile.jpg",
//       isIncoming: false,
//     ),
//   ),
// );