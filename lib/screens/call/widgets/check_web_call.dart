import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;



class CallScreen extends StatefulWidget {
  final String userId;

  const CallScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late IO.Socket socket;
  String? receiverId;
  Timer? callTimer;
  DateTime? callStartTime;
  final int callDurationLimit = 5 * 60; // seconds
  String callTime = "00:00";
  bool inCall = false;

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  void initSocket() {
    socket = IO.io("https://picturoenglish.com:2027", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });

    socket.connect();

    socket.onConnect((_) {
      print("Socket connected");
      socket.emit("register", widget.userId);
    });

    socket.on("incoming-call", (data) {
      receiverId = data["from"];
      String name = data["name"];
      showIncomingCallDialog(name);
    });

    socket.on("call-accepted", (_) {
      initiateCall();
    });

    socket.on("call-rejected", (_) {
      showAlert("Call was rejected");
      endCall();
    });

    socket.onDisconnect((_) => print("Disconnected"));
  }

  void showIncomingCallDialog(String callerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("$callerName is calling..."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              answerCall();
            },
            child: Text("Accept"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              rejectCall();
            },
            child: Text("Reject"),
          ),
        ],
      ),
    );
  }

  void answerCall() {
    if (receiverId != null) {
      socket.emit("call-accepted", {"to": receiverId});
    }
  }

  void rejectCall() {
    if (receiverId != null) {
      socket.emit("call-rejected", {"to": receiverId});
    }
  }

  void initiateCall() {
    setState(() {
      inCall = true;
    });
    startCallTimer();
  }

  void startCallTimer() {
    callStartTime = DateTime.now();
    callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(callStartTime!).inSeconds;
      final minutes = (elapsed ~/ 60).toString().padLeft(2, '0');
      final seconds = (elapsed % 60).toString().padLeft(2, '0');
      setState(() {
        callTime = "$minutes:$seconds";
      });

      if (elapsed >= callDurationLimit) {
        showAlert("Call limit reached. Ending call.");
        endCall();
      }
    });
  }

  void stopCallTimer() {
    callTimer?.cancel();
    setState(() {
      callTime = "00:00";
      inCall = false;
    });
  }

  void endCall() {
    if (receiverId != null) {
      socket.emit("endCall", {"to": receiverId});
    }
    stopCallTimer();
  }

  void showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Notice"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socket.dispose();
    callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Call Socket status-  ${socket.connected}");
    return Scaffold(
      appBar: AppBar(title: Text("Call Screen")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (inCall)
              Column(
                children: [
                  Text("In Call", style: TextStyle(fontSize: 20)),
                  SizedBox(height: 10),
                  Text(callTime, style: TextStyle(fontSize: 32)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: endCall,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text("End Call"),
                  ),
                ],
              )
            else
              Text("Waiting for calls...", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
