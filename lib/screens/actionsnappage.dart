import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// import 'package:video_player/video_player.dart';

import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/screens/actionsnaptopics.dart';
import '../utils/common_app_bar.dart';

class ActionSnapApp extends StatefulWidget {
  const ActionSnapApp({super.key,required this.topic});
  final String topic;

  @override
  _ActionSnapAppState createState() => _ActionSnapAppState();
}

class _ActionSnapAppState extends State<ActionSnapApp> {
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  File? _videoFile;
  bool _isUploading = false;
  String? _topActionText;

  Future<void> pickVideo(BuildContext context) async {
    final pickedFile = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30),
    );

    if (pickedFile != null) {
      File video = File(pickedFile.path);
      setState(() {
        _videoFile = video;
      });

      final duration = await _getVideoDuration(video);
      if (duration >= Duration(seconds: 30)) {
        uploadVideo();
      } else {
        _showUploadConfirmationDialog(context);
      }
    }
  }

  Future<Duration> _getVideoDuration(File videoFile) async {
    // final controller = VideoPlayerController.file(videoFile);
    // await controller.initialize();
    // final duration = controller.value.duration;
    // await controller.dispose();
    return Duration();
  }

  void _showUploadConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Upload Video?"),
        content: const Text("Video is less than 30 seconds. Do you want to upload it?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              uploadVideo();
            },
            child: const Text("Upload"),
          ),
        ],
      ),
    );
  }

  Future<void> uploadVideo() async {
    if (_videoFile == null) return;

    setState(() {
      _isUploading = true;
      _topActionText = null;
    });


    try {
      var uri = Uri.parse('http://37.27.187.66:2028/upload');
      var request = http.MultipartRequest('POST', uri);
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? token = pref.getString("auth_token");

      request.headers.addAll({
        "Authorization": "Bearer $token",
        'Content-Type': 'multipart/form-data',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          _videoFile!.path,
          filename: basename(_videoFile!.path),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = TopActionsResponse.fromJson(jsonDecode(response.body));

        if (decoded.detectedActions != null && decoded.detectedActions!.isNotEmpty) {
          setState(() {
            _topActionText = decoded.detectedActions!.first;
          });
          Fluttertoast.showToast(msg: "Your video has been analyzed", backgroundColor: Colors.green);

        }else{
          Fluttertoast.showToast(msg: "No action found in your video", backgroundColor: Colors.red);

        }

      } else {
        Fluttertoast.showToast(msg: "Failed to Load Video", backgroundColor: Colors.red);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e", backgroundColor: Colors.red);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2E7),
      appBar: CommonAppBar(title: "Action Snap", isBackbutton: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEEEFFF),
              Color(0xFFFFF0D3),
              Color(0xFFE7F8FF),
              Color(0xFFEEEFFF)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Text(
                "Upload Video Related ${widget.topic.toUpperCase()}",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF49329A),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () => pickVideo(context),
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color:_topActionText!=null? Colors.green: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        spreadRadius: 2,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _isUploading
                      ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : _capturedImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.string(
                        Svgfiles.cameraSvg,
                        width: 22,
                        height: 22,
                      ),
                      SizedBox(height: 10),
                      _topActionText !=null? Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "Detected Action : ${(_topActionText)?.toUpperCase()}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins Regular',
                            fontSize: _topActionText!=null?18:16,
                            fontWeight: _topActionText!=null?  FontWeight.w800: FontWeight.w500,
                            color:_topActionText!=null? Colors.black: Colors.grey,
                          ),
                        ),
                      ): Text(
                        _topActionText ?? "Capture",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins Regular',
                          fontSize: _topActionText!=null?18:16,
                          fontWeight: _topActionText!=null?  FontWeight.w800: FontWeight.w500,
                          color:_topActionText!=null? Colors.black: Colors.grey,
                        ),
                      ),
                    ],
                  )
                      : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          _capturedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      if (_topActionText != null)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _topActionText!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Snap Shot is a game where you take pictures that match given words. If the word is \"run,\" snap a photo of someone running. Capture the right moments.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins Regular',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Top Action Response Model
class TopActionsResponse {
  List<String>? detectedActions;

  TopActionsResponse({this.detectedActions});

  factory TopActionsResponse.fromJson(Map<String, dynamic> json) {
    return TopActionsResponse(
      detectedActions: List<String>.from(json['result']['detected_actions'] ?? []),
    );
  }
}