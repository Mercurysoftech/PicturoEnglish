import 'package:flutter/material.dart';
import 'package:picturo_app/screens/dragandlearnpage.dart';
import 'package:picturo_app/screens/gamespage.dart';
import 'package:picturo_app/screens/picturegrammerquest.dart';
import 'package:picturo_app/screens/actionsnappage.dart';
import 'package:picturo_app/screens/widgets/drag_and_learn_level.dart';

import '../utils/common_app_bar.dart';
import '../utils/common_file.dart';
import 'games/drag_and_learn_topics.dart';

class DragandLearnTopicScreen extends StatefulWidget {
  String? gameName;
  DragandLearnTopicScreen({super.key, this.gameName});

  @override
  _DragandLearnTopicScreenState createState() => _DragandLearnTopicScreenState();
}

class _DragandLearnTopicScreenState extends State<DragandLearnTopicScreen> {
  // Define grammar topics with distinct colors and icons
  final List<Map<String, dynamic>> _grammarTopics = [
    {
      'title': 'Verbs',
      'description': 'Action words and their forms',
      'color': Color(0xFF4285F4), // Blue
      'icon': Icons.directions_run,
    },
    {
      'title': 'Adverbs',
      'description': 'Words that modify verbs',
      'color': Color(0xFF34A853), // Green
      'icon': Icons.speed,
    },
    {
      'title': 'Adjectives',
      'description': 'Words that describe nouns',
      'color': Color(0xFFEA4335), // Red
      'icon': Icons.format_color_fill,
    },
    {
      'title': 'Phrasal Verbs',
      'description': 'Verb + preposition combinations',
      'color': Color(0xFFFBBC05), // Yellow
      'icon': Icons.call_split,
    },
    {
      'title': 'Idioms',
      'description': 'Expressions with figurative meanings',
      'color': Color(0xFF673AB7), // Purple
      'icon': Icons.lightbulb_outline,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: CommonAppBar(title:"Drag and Learn",isBackbutton: true,),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              child: Text(
                'Topics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppConstants.commonFont,
                  color: Color(0xFF414141),
                ),
            ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _grammarTopics.length,
                itemBuilder: (context, index) {
                  final topic = _grammarTopics[index];
                  return _buildGrammarCard(index,
                    context,
                    topic['title'],
                    topic['description'],
                    topic['color'],
                    topic['icon'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrammarCard(int bookId, BuildContext context, String title, String description, Color color, IconData icon) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DLGameTopicsPage(title:title ,topicId: bookId+1,)),
            );

        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppConstants.commonFont,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontFamily: AppConstants.commonFont,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}