import 'package:flutter/material.dart';

class LearningTitlePageScreen extends StatefulWidget {
  const LearningTitlePageScreen({super.key});

  @override
  _LearningTitlePageScreenState createState() =>
      _LearningTitlePageScreenState();
}

class _LearningTitlePageScreenState extends State<LearningTitlePageScreen> {
  double progress = 0.3; // Progress percentage
  final dest = 100;
  List<bool> isUnlocked = [true, false, false, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  'Picture Grammar Quest',
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF49329A)),
                      minHeight: 12,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "${(progress * 100).toInt()}%",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Questions List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, index) {
                bool isLocked = !isUnlocked[index];
                return GestureDetector(
                  onTap: () {
                    if (!isLocked) {
                      // Navigate to another page when the item is clicked
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(index: index + 1),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey[400] : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isLocked ? Colors.grey[700] : Colors.blue,
                        child: Text("${index + 1}",
                            style: TextStyle(color: Colors.white)),
                      ),
                      title: Text(
                        "Sentence ${index + 1}",
                        style: TextStyle(
                          color: isLocked ? Colors.black45 : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: isLocked
                          ? Icon(Icons.lock, color: Colors.black45)
                          : null,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Example Detail Page
class DetailPage extends StatelessWidget {
  final int index;
  const DetailPage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sentence $index")),
      body: Center(child: Text("Details for Sentence $index")),
    );
  }
}
