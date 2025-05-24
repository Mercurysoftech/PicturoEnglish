import 'package:flutter/material.dart';
import 'package:picturo_app/screens/dragandlearnpage.dart';
import 'package:picturo_app/screens/picturegrammerquest.dart';
import 'package:picturo_app/screens/actionsnappage.dart';

class ActionSnapTopicsScreen extends StatefulWidget {
  String? gameName;
  ActionSnapTopicsScreen({super.key, this.gameName});

  @override
  _ActionSnapTopicsScreenState createState() => _ActionSnapTopicsScreenState();
}

class _ActionSnapTopicsScreenState extends State<ActionSnapTopicsScreen> {
  // Simplified topics list with only core grammar elements
  final List<Map<String, dynamic>> _grammarTopics = [
    {
      'title': 'Verbs',
      'description': 'Action words (run, eat, think)',
      'color': Color(0xFF4E7AC7), // Deep blue
      'icon': Icons.directions_run,
    },
    {
      'title': 'Adverbs',
      'description': 'Modify verbs (quickly, silently)',
      'color': Color(0xFF5CB85C), // Fresh green
      'icon': Icons.speed,
    },
    {
      'title': 'Adjectives',
      'description': 'Describe nouns (happy, blue, large)',
      'color': Color(0xFFD9534F), // Warm red
      'icon': Icons.format_color_fill,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF49329A),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.gameName!,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        elevation: 0,
        ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16),
              child: Text(
                'Core Grammar Topics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF343A40),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                physics: ClampingScrollPhysics(),
                separatorBuilder: (_, __) => SizedBox(height: 16),
                itemCount: _grammarTopics.length,
                itemBuilder: (context, index) {
                  final topic = _grammarTopics[index];
                  return _GrammarConceptCard(
                    title: topic['title'],
                    description: topic['description'],
                    color: topic['color'],
                    icon: topic['icon'],
                    onTap: () => _navigateToGame(context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context) {
    switch (widget.gameName) {
      case 'Drag and Learn':
        // Navigator.push(context, MaterialPageRoute(builder: (_) => DragAndLearnApp(level: null,)));
        break;
      case 'Picture Grammar Quest':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PictureGrammarQuestScreen()));
        break;
      case 'Action Snap':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ActionSnapApp()));
        break;
    }
  }
}

class _GrammarConceptCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _GrammarConceptCard({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}