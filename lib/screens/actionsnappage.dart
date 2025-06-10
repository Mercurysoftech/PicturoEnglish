import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/screens/actionsnaptopics.dart';

import '../utils/common_app_bar.dart';
import '../utils/common_file.dart';


class ActionSnapApp extends StatefulWidget {
  const ActionSnapApp({super.key});

  @override
  _ActionSnapAppState createState() => _ActionSnapAppState();
}

class _ActionSnapAppState extends State<ActionSnapApp> {
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _capturedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
    canPop: false,
    onPopInvoked: (didPop) async {
      if (!didPop) {
        // Navigate to your desired screen instead of closing
        Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ActionSnapTopicsScreen(
                                      ),
                                    ),
                                  );
      }
    },
    child:
    Scaffold(
      backgroundColor: const Color(0xFFF8F2E7),
      appBar: CommonAppBar(title:"Action Snap" ,isBackbutton: true,),
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
              Text("Jump",
                  style: TextStyle(
                    fontFamily: AppConstants.commonFont,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF49329A),
                  )),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        spreadRadius: 2,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _capturedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.string(
                              Svgfiles.cameraSvg,
                              width: 22,
                              height: 22,
                            ),
                            SizedBox(height: 10),
                            Text("Capture",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins Regular',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                )),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _capturedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )),
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
    ),
    );
  }
}
