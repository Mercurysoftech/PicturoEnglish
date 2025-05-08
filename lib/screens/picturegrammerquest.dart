import 'package:flutter/material.dart';
import 'package:picturo_app/screens/grammerquestscreen.dart';
import 'package:picturo_app/screens/homepage.dart';

class PictureGrammarQuestScreen extends StatelessWidget {
  final double progress = 0.1;
  final List<Map<String, dynamic>> levels = [
    {'number': 1, 'text': 'He ran quickly through the dark alley', 'locked': false},
    {'number': 2, 'text': 'She spoke softly to the nervous child', 'locked': true},
    {'number': 3, 'text': 'They worked diligently on the complicated project', 'locked': true},
    {'number': 4, 'text': 'The dog barked loudly at the strange visitor', 'locked': true},
    {'number': 5, 'text': 'She waited patiently for the delayed train', 'locked': true},
    {'number': 6, 'text': 'He smiled cheerfully at his beautiful wife', 'locked': true},
    {'number': 7, 'text': 'He answered confidently despite the tricky question', 'locked': true},
  ];
  final String? title;

  PictureGrammarQuestScreen({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Homepage()),
                );
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Text(
              'Picture Grammar Quest',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins Regular',
              ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF49329A)),
                        minHeight: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A2D91)),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final level = levels[index];
                return GestureDetector(
                  onTap: () {
                    if (!level['locked']) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GrammarQuestScreen(title: level['text']),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 20),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: level['locked'] ? Colors.grey[400] : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFF49329A),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            level['number'].toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF49329A),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            level['text'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins Regular',
                              color: level['locked'] ? Colors.black54 : Colors.black,
                            ),
                          ),
                        ),
                        if (level['locked'])
                          Icon(Icons.lock, color: Colors.white),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}