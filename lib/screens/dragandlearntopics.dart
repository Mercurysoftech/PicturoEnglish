import 'package:flutter/material.dart';
import 'package:picturo_app/screens/dragandlearnpage.dart';
import 'package:picturo_app/screens/gamespage.dart';
import 'package:picturo_app/screens/picturegrammerquest.dart';
import 'package:picturo_app/screens/actionsnappage.dart';

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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // Increased app bar height
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0), // Adjust top padding
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {       
        Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GamesPage(
                                      ),
                                    ),
                                  );
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
                  fontFamily: 'Poppins Regular',
                  color: Color(0xFF414141),
                ),
            ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _grammarTopics.length,
                itemBuilder: (context, index) {
                  final topic = _grammarTopics[index];
                  return _buildGrammarCard(
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

  Widget _buildGrammarCard(BuildContext context, String title, String description, Color color, IconData icon) {
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
              MaterialPageRoute(builder: (context) => DragAndLearnApp()),
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
                        fontFamily: 'Poppins Regular',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontFamily: 'Poppins Regular',
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