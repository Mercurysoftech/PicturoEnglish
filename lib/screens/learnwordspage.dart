import 'package:flutter/material.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/responses/question_details_response.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../responses/my_profile_response.dart';


class LearnWordsPage extends StatefulWidget {
  final String? optionTitle;
  final int? questionId;
  final String? bookId;
  final String? topicId;
  const LearnWordsPage({super.key,this.optionTitle, this.questionId,required this.bookId,required this.topicId});
  

  @override
  State<LearnWordsPage> createState() => _LearnWordsPageState();
}

class _LearnWordsPageState extends State<LearnWordsPage> {
  late Future<QuestionDetailsResponse> _questionFuture;
  bool _isLoading = true;
  String _errorMessage = '';
  QuestionDetailsResponse? _questionData;
  ApiService? apiService;
  String? userLanguage;
  bool _languageLoaded = false;
  UserResponse? userResponse;

   @override
  void initState() {
    super.initState();
    fetchUserDetails();
    readQuestion();
    initializeApiService();
  }


  Future<void> fetchUserDetails() async {
    try {
      final apiService = await ApiService.create();
      final response = await apiService.fetchProfileDetails();

      setState(() {
        userResponse=response;
        userLanguage=userResponse?.speakingLanguage??'';
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching questions: ${e.toString()}";

      });
      print("Error fetching questions: $e");
    }
  }
  Future<void> readQuestion() async {
    try {
      final apiService = await ApiService.create();
      final response = await apiService.readMarkAsRead(bookId: widget.bookId.toString(), topicId: widget.topicId.toString(), questionId: widget.questionId.toString());

    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching questions: ${e.toString()}";

      });
      print("Error fetching questions: $e");
    }
  }

   Future<void> initializeApiService() async {
    apiService = await ApiService.create();
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    // userLanguage=userResponse?.speakingLanguage??'';

    print('Language is heres: $userLanguage');

    setState(() {
      _languageLoaded = true; // Mark language as loaded
    });

    if (widget.questionId != null && apiService != null) {
      _questionFuture = apiService!.fetchDetailedQuestion(widget.questionId!);
      _loadQuestionData();
    }
    
  }

  Future<void> _loadQuestionData() async {
    // try {
      final questionData = await _questionFuture;
      setState(() {
        _questionData = questionData;
        _isLoading = false;
      });
    // } catch (e) {
    //   setState(() {
    //     _errorMessage = "Error loading question: $e";
    //     _isLoading = false;
    //   });
    //   print("Error loading question: $e");
    // }
  }

  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
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
                  widget.optionTitle ?? 'Learn Words',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
      body:  !_languageLoaded || _isLoading
        ? Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Center(
  child: SizedBox(
    height: 280,
    width: 280,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: _questionData?.qusImage != null
          ? Stack(
              children: [
                // Shimmer effect as placeholder
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    color: Colors.white,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                ),
                // Actual image
                Image.network(
                  'https://picturoenglish.com/admin/${_questionData!.qusImage}',
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.white,
                        height: double.infinity,
                        width: double.infinity,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset('assets/run.gif');
                  },
                ),
              ],
            )
          : Image.asset('assets/run.gif'),
    ),
  ),
),
                    SizedBox(height: 20),
                    Text(
                      _questionData?.question ?? 'No question',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins Regular',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meaning',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins Regular',
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            _questionData?.meaning ?? 'No meaning available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF515151),
                              fontFamily: 'Poppins Regular',
                            ),
                          ),
                          SizedBox(height: 20),
                          // In your LearnWordsPage's build method, replace the Native Meaning section with this:

if (userLanguage?.toLowerCase() != 'english') ...[
  Text(
    'Native Meaning',
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      fontFamily: 'Poppins Regular',
    ),
  ),
  SizedBox(height: 10),
  if (_questionData?.nativeMeaning != null && 
      _questionData!.nativeMeaning!.isNotEmpty)
    _buildNativeMeaningBasedOnLanguage(
      _questionData!.nativeMeaning[0], 
      userLanguage
    ) ??


    Text(
      'No Native meaning available',
      style: TextStyle(
        fontSize: 16,
        color: Color(0xFF515151),
        fontFamily: 'Poppins Regular',
      ),
    ),
  SizedBox(height: 20),
],
                          Text(
                            'Examples',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins Regular',
                            ),
                          ),
                          SizedBox(height: 18),
                          ...?_questionData?.examples!.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final example = entry.value;

                            final languageExample = _getExampleBasedOnLanguage(example, userLanguage);
                            return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$index. ${example.english ?? 'No English example'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF515151),
                                  fontFamily: 'Poppins Regular',
                                ),
                              ),
                              SizedBox(height: 10),
                              if (languageExample != null)
                                Text(
                                  '$index. $languageExample',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF515151),
                                    fontFamily: 'Poppins Regular',
                                  ),
                                ),
                              SizedBox(height: 18),
                            ],
                          );
                        }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
  );
}
Widget? _buildNativeMeaningBasedOnLanguage(NativeMeaning nativeMeaning, String? userLanguage) {
  // Default to English if no language is selected
  if (userLanguage?.toLowerCase() == 'english') {
    return null;
  }
  
  final language = userLanguage?.toLowerCase() ?? 'english';
  
  String? meaning;
  
  switch (language) {
    case 'tamil':
      meaning = nativeMeaning.tamil;
      break;
    case 'hindi':
      meaning = nativeMeaning.hindi;
      break;
    case 'telugu':
      meaning = nativeMeaning.telugu;
      break;
    case 'malayalam':
      meaning = nativeMeaning.malayalam;
      break;
    default:
      // If language not matched, show the first available meaning
      meaning = nativeMeaning.tamil ?? 
               nativeMeaning.hindi ?? 
               nativeMeaning.telugu ?? 
               nativeMeaning.malayalam;
  }
  
   return meaning != null ? Text(
    meaning,
    style: TextStyle(
      fontSize: 16,
      color: Color(0xFF515151),
      fontFamily: 'Poppins Regular',
    ),
  ) : null;
}

String? _getExampleBasedOnLanguage(Example example, String? userLanguage) {
  
  if (userLanguage?.toLowerCase() == 'english') {
    return null;
  }
  print("aljkclaksm ${userLanguage}");

  final language = userLanguage?.toLowerCase() ?? 'english';
  
  switch (language) {
    case 'tamil':
      return example.tamil;
    case 'hindi':
      return example.hindi;
    case 'telugu':
      return example.telugu;
    case 'malayalam':
      return example.malayalam;
    default:
      // Return the first available translation if specific language not found
      return example.tamil ?? 
             example.hindi ?? 
             example.telugu ?? 
             example.malayalam;
  }
}
}
