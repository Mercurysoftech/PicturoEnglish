import 'package:flutter/material.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/responses/question_details_response.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/utils/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../cubits/content_view_per_get/content_view_percentage_cubit.dart';
import '../cubits/get_sub_topics_list/get_sub_topics_list_cubit.dart';
import '../main.dart';
import '../responses/my_profile_response.dart';
import '../utils/common_app_bar.dart';
import '../utils/common_file.dart';


class LearnWordsPage extends StatefulWidget {
  final int? questionId;
  final String? bookId;
  final int? topicId;
  const LearnWordsPage({super.key, this.questionId,required this.bookId,required this.topicId});
  

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

      if(response!=null&&response){
        context.read<ProgressCubit>().fetchProgress(isFromTopic: true,bookId: int.parse(widget.bookId??"0"), topicId: widget.topicId??0);
        context.read<SubtopicCubit>().fetchQuestions(widget.topicId!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching questions: ${e.toString()}";

      });
      print("Error fetching questions: $e");
    }
  }

   Future<void> initializeApiService() async {
    apiService = await ApiService.create();
    // userLanguage=userResponse?.speakingLanguage??'';

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
      appBar: CommonAppBar(title:"Learn Words",isBackbutton: true,),
      body:  !_languageLoaded || _isLoading
        ? Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage))
            : Scrollbar(
              child: SingleChildScrollView(
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
                  CachedNetworkImageWidget(
                    imageUrl: 'https://picturoenglish.com/admin/${_questionData!.qusImage}',
                    fit: BoxFit.cover,
                    width: 300,
                    height: 300,
                    errorWidget: (context, error, stackTrace) {
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
                          fontFamily: AppConstants.commonFont,
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
                                fontFamily: AppConstants.commonFont,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              capitalizeFirstLetter(_questionData?.meaning ?? 'No meaning available'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF515151),
                                fontFamily: AppConstants.commonFont,
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
                    fontFamily: AppConstants.commonFont,
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
                      fontFamily: AppConstants.commonFont,
                    ),
                  ),
                SizedBox(height: 20),
              ],
                            Text(
                              'Examples',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppConstants.commonFont,
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
                                    fontFamily: AppConstants.commonFont,
                                  ),
                                ),
                                SizedBox(height: 10),
                                if (languageExample != null)
                                  Text(
                                    '$index. $languageExample',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF515151),
                                      fontFamily: AppConstants.commonFont,
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
      fontFamily: AppConstants.commonFont,
    ),
  ) : null;
}

String? _getExampleBasedOnLanguage(Example example, String? userLanguage) {
  
  if (userLanguage?.toLowerCase() == 'english') {
    return null;
  }


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
