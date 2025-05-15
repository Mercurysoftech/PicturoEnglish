import 'package:flutter/material.dart';
import 'package:picturo_app/responses/questions_response.dart';
import 'package:picturo_app/screens/widgets/cat_progress_bar_widget.dart';
import 'package:picturo_app/services/api_service.dart'; 
import 'package:picturo_app/screens/learnwordspage.dart';

import '../responses/my_profile_response.dart';

class SubtopicPage extends StatefulWidget {
  final String? title;
  final int? topicId; 
  final int? bookId;
  const SubtopicPage({super.key,required this.title,required this.topicId,required this.bookId});

  @override
  _SubtopicPageState createState() => _SubtopicPageState();
}

class _SubtopicPageState extends State<SubtopicPage> {
  int selectedOption = -1; 
  List<Question> _questions = []; 
  bool _isLoading = true; 
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    fetchQuestionsAndUpdateUI();
  }


Future<void> fetchQuestionsAndUpdateUI() async {
  try {
    final apiService = await ApiService.create();
    final response = await apiService.fetchQuestions(widget.topicId!);

    setState(() {
      if (response.status=='success') {
        _questions = response.questions ?? [];
      } else {
        _errorMessage = response.message ?? 'No questions found for this topic';
      }
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _errorMessage = "Error fetching questions: ${e.toString()}";
      _isLoading = false;
    });
    print("Error fetching questions: $e");
  }
}

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
                Navigator.pop(context); 
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Row(
              children: [
                Text(
                  widget.title!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Bar
          ProgressBarWidget(bookId: widget.bookId??0,topicId: widget.topicId??0,),
          SizedBox(height: 20),

          // List of Options
         Expanded(
  child: _isLoading
      ? Center(child: CircularProgressIndicator())
      : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontFamily: 'Poppins Medium',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF49329A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    ),
                    onPressed: fetchQuestionsAndUpdateUI,
                    child: Text('Retry',style: TextStyle(fontFamily: 'Poppins Medium',color: Colors.white),),
                  ),
                ],
              ),
            )
          : _questions.isEmpty
              ? Center(
                  child: Text(
                    'No questions available for this topic',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: _questions.map((question) {
                    int index = _questions.indexOf(question);
                    return optionTile(index + 1, question);
                  }).toList(),
                ),
),
        ],
      ),
    );
  }

  // Option Tile Widget
  Widget optionTile(int number, Question question) {
  bool isSelected = selectedOption == number;
  return GestureDetector(
    onTap: () {
      setState(() {
        selectedOption = number;
      });
      // Navigate to LearnWordsPage with both the text and ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LearnWordsPage(
            optionTitle: question.question ?? '',
            questionId: question.id ?? 0, // Pass the question ID
          ),
        ),
      );
    },
    child: Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.green : Color(0xFF49329A),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              number.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green : Color(0xFF49329A),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              question.question ?? '', // Use the question text
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontFamily: 'Poppins Regular',
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
        ],
      ),
    ),
  );
}
}