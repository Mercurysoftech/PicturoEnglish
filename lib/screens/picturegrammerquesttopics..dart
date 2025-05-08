import 'package:flutter/material.dart';
import 'package:picturo_app/screens/dragandlearnpage.dart';
import 'package:picturo_app/screens/picturegrammerquest.dart';
import 'package:picturo_app/screens/actionsnappage.dart';

class PictureGrammerTopicScreen extends StatefulWidget {
  final String gameName;
  const PictureGrammerTopicScreen({super.key, required this.gameName});

  @override
  _PictureGrammerTopicScreenState createState() => _PictureGrammerTopicScreenState();
}

class _PictureGrammerTopicScreenState extends State<PictureGrammerTopicScreen> {
  // Grammar topics with emoji icons and accent colors
  final List<Map<String, dynamic>> _grammarTopics = [
    {
      'title': 'Verbs',
      'emoji': '🏃',
      'color': Colors.blue.shade100,
      'textColor': Colors.blue.shade800,
    },
    {
      'title': 'Adverbs',
      'emoji': '⚡',
      'color': Colors.green.shade100,
      'textColor': Colors.green.shade800,
    },
    {
      'title': 'Adjectives',
      'emoji': '🎨',
      'color': Colors.red.shade100,
      'textColor': Colors.red.shade800,
    },
    {
      'title': 'Phrasal Verbs',
      'emoji': '🧩',
      'color': Colors.orange.shade100,
      'textColor': Colors.orange.shade800,
    },
    {
      'title': 'Idioms',
      'emoji': '💡',
      'color': Colors.purple.shade100,
      'textColor': Colors.purple.shade800,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // Increased app bar height
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0), // Adjust top padding
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {},
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0), // Adjust top padding
            child: Row(
              children: [
                Text(
                  widget.gameName,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 20.0),
              child: Text(
                'Topics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins Regular',
                  color: Colors.grey[800],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                physics: BouncingScrollPhysics(),
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemCount: _grammarTopics.length,
                itemBuilder: (context, index) {
                  final topic = _grammarTopics[index];
                  return _GrammarTopicCard(
                    emoji: topic['emoji'],
                    title: topic['title'],
                    color: topic['color'],
                    textColor: topic['textColor'],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PictureGrammarQuestScreen())),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrammarTopicCard extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _GrammarTopicCard({
    required this.emoji,
    required this.title,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor, // Use the provided color for border
          width: 1,   // Adjust border width as needed
        ),
      ),
      child:
    Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: 24,fontFamily: 'Poppins Regular',),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins Regular',
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 28,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}