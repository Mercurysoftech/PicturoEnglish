import 'package:flutter/material.dart';
import 'package:picturo_app/screens/dragandlearntopics.dart';

import '../models/dragand_learn_model.dart';

class DragAndLearnApp extends StatefulWidget {
  const DragAndLearnApp({super.key,required this.level});
  final Levels? level;

  @override
  _DragAndLearnAppState createState() => _DragAndLearnAppState();
}

class _DragAndLearnAppState extends State<DragAndLearnApp> {
  late List<String?> words;
  late List<String?> images;

  // Map to store which image is correctly placed on each word
  Map<String?, String?> placedImages = {};
  List<String?> availableImages = [];

  @override
  void initState() {
    super.initState();
    if(widget.level?.questions!=null){
      words = widget.level!.questions!.map((q) => q.question).toList();
      images = widget.level!.questions!.map((q) => q.qusImage).toList();
    }

// Assuming qus_image is qusImage in your model

    for (var word in words) {
      placedImages[word] = null;
    }

    availableImages = List.from(images);
  }
  void _showCongratulationsPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Congratulations!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5E3FA0),
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            "You matched all correctly.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "OK",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double itemSize = 100; // Set uniform size for items

    return PopScope(
    canPop: false,
    onPopInvoked: (didPop) async {
      if (!didPop) {
        // Navigate to your desired screen instead of closing
        Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DragandLearnTopicScreen(
                                      ),
                                    ),
                                  );
      }
    },
    child:
    Scaffold(
      backgroundColor: const Color(0xFFF7F1E6),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // Increased app bar height
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0), // Adjust top padding
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {       
       Navigator.pop(context);
      },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0), // Adjust top padding
            child: Row(
              children: [
                Text(
                  'Drag and Learn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins Regular',
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Verb",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

             SizedBox(
  height: itemSize * 2 + 50, // Ensures 2 rows fit properly
  child: GridView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(), // Prevents nested scrolling
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, // 3 Columns
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1, // Ensures square items
    ),
    itemCount: words.length,
    itemBuilder: (context, index) {
      String? word = words[index];
      return DragTarget<String>(
        onWillAcceptWithDetails: (data) => true,
        onAccept: (imagePath) {
          int wordIndex = words.indexOf(word);
          int imageIndex = images.indexOf(imagePath);
          if (wordIndex == imageIndex) {
            setState(() {
              placedImages[word] = imagePath;
              availableImages.remove(imagePath);
            });
          }
          if (placedImages.values.every((value) => value != null)) {
            Future.delayed(const Duration(milliseconds: 300), _showCongratulationsPopup);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return SizedBox(
            width: itemSize,
            height: itemSize,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFCBBCFF), width: 1),
              ),
              alignment: Alignment.center,
              child: placedImages[word] != null
                  ? Image.network("https://picturoenglish.com/admin/${placedImages[word]!}", fit: BoxFit.cover)
                  : Text(
                      word??'',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF49329A),
                      ),
                    ),
            ),
          );
        },
      );
    },
  ),
),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF49329A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Drag and place the picture into the correct container",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),

              // Draggable Images Grid (Always 2 Rows x 3 Columns)
              SizedBox(
                height: itemSize * 2 + 50, // Fixed height for 2 rows
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(), // Prevent nested scroll
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Always 3 columns
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1, // Square items
                  ),
                  itemCount: availableImages.length,
                  itemBuilder: (context, index) {
                    return Draggable<String>(
                      data: availableImages[index],
                      feedback: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: itemSize,
                          height: itemSize,
                          child: Image.network("https://picturoenglish.com/admin/${availableImages[index]??''}", fit: BoxFit.cover),
                        ),
                      ),
                      childWhenDragging: SizedBox(
                        width: itemSize,
                        height: itemSize,
                        child: Container(color: Colors.transparent),
                      ),
                      child: SizedBox(
                        width: itemSize,
                        height: itemSize,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network("https://picturoenglish.com/admin/${availableImages[index]??''}", fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    );
                  },
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
