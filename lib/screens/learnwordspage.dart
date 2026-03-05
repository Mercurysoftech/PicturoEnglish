import 'dart:io';

import 'package:flutter/material.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/responses/question_details_response.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/utils/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  final String quesImage;
  const LearnWordsPage(
      {super.key,
      this.questionId,
      required this.bookId,
      required this.topicId,
      required this.quesImage});

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

      if (mounted) {
        setState(() {
          userResponse = response;
          userLanguage = userResponse?.user.speakingLanguage ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error fetching questions: ${e.toString()}";
        });
      }
      print("Error fetching questions: $e");
    }
  }

  Future<void> readQuestion() async {
    try {
      final apiService = await ApiService.create();
      final response = await apiService.readMarkAsRead(
          bookId: widget.bookId.toString(),
          topicId: widget.topicId.toString(),
          questionId: widget.questionId.toString());

      if (response != null && response && mounted) {
        context.read<ProgressCubit>().fetchProgress(
            isFromTopic: true,
            bookId: int.parse(widget.bookId ?? "0"),
            topicId: widget.topicId ?? 0);
        context.read<SubtopicCubit>().fetchQuestions(widget.topicId!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error fetching questions: ${e.toString()}";
        });
      }
      print("Error fetching questions: $e");
    }
  }

  Future<void> initializeApiService() async {
    apiService = await ApiService.create();

    if (mounted) {
      setState(() {
        _languageLoaded = true;
      });
    }

    if (widget.questionId != null && apiService != null) {
      _questionFuture = apiService!.fetchDetailedQuestion(widget.questionId!);
      await _loadQuestionData();
    }
  }

  Future<void> _loadQuestionData() async {
    try {
      final questionData = await _questionFuture;

      if (mounted) {
        setState(() {
          _questionData = questionData;
          _isLoading = false;
        });

        if (_questionData?.qusImage != null) {
          print(
              "Image URL: https://picturoenglish.com/admin/${_questionData!.qusImage}");
        } else {
          print("No image URL available");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading question: $e";
          _isLoading = false;
        });
      }
      print("Error loading question: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: CommonAppBar(title: "Learn Words", isBackbutton: true),
      body: !_languageLoaded || _isLoading
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
  child: buildQuestionImage(widget.quesImage),
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
                                capitalizeFirstLetter(_questionData?.meaning ??
                                    'No meaning available'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF515151),
                                  fontFamily: AppConstants.commonFont,
                                ),
                              ),
                              SizedBox(height: 20),
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
                                          userLanguage) ??
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
                              ...?_questionData?.examples!
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key + 1;
                                final example = entry.value;

                                final languageExample =
                                    _getExampleBasedOnLanguage(
                                        example, userLanguage);
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

Widget buildQuestionImage(String imagePath) {
  // LOCAL FILE IMAGE
  if (imagePath.startsWith('/') && imagePath.contains('/data/')) {
    // It's a proper absolute path to local storage
    final file = File(imagePath);
    
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white),
          );
        }
        
        if (snapshot.hasData && snapshot.data == true) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return _imageErrorWidget("Local image load failed");
            },
          );
        }
        
        // File doesn't exist, fall back to remote
        debugPrint('Local file not found: $imagePath');
        return _buildRemoteImageFallback();
      },
    );
  }

  // REMOTE IMAGE (or invalid local path like "/uploads/...")
  return _buildRemoteImage(imagePath);
}

Widget _buildRemoteImage(String imagePath) {
  String imageUrl;
  if (imagePath.startsWith('http')) {
    imageUrl = imagePath;
  } else if (imagePath.startsWith('uploads/')) {
    imageUrl = 'https://picturoenglish.com/admin/$imagePath';
  } else if (imagePath.startsWith('/uploads/')) {
    imageUrl = 'https://picturoenglish.com/admin$imagePath';
  } else {
    imageUrl = 'https://picturoenglish.com/admin/${imagePath.startsWith('/') ? imagePath.substring(1) : imagePath}';
  }

  debugPrint('Loading remote image from: $imageUrl');

  return CachedNetworkImage(
    imageUrl: imageUrl,
    fit: BoxFit.cover,
    placeholder: (context, url) => Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    ),
    errorWidget: (context, url, error) {
      debugPrint('Remote image load error for $url: $error');
      return _imageErrorWidget('Unable to load image');
    },
  );
}

Widget _buildRemoteImageFallback() {
  // Show loading state - data will be refetched automatically
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: Color(0xFF49329A),
        ),
        SizedBox(height: 10),
        Text(
          'Loading image...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

Widget _imageErrorWidget(String message) {
  return Container(
    color: Colors.grey[200],
    alignment: Alignment.center,
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Colors.redAccent,
        ),
        const SizedBox(height: 10),
        const Text(
          'Image failed to load',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            initializeApiService();
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Retry'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF49329A),
          ),
        ),
      ],
    ),
  );
}


  Widget? _buildNativeMeaningBasedOnLanguage(
      NativeMeaning nativeMeaning, String? userLanguage) {
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
        meaning = nativeMeaning.tamil ??
            nativeMeaning.hindi ??
            nativeMeaning.telugu ??
            nativeMeaning.malayalam;
    }

    return meaning != null
        ? Text(
            meaning,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF515151),
              fontFamily: AppConstants.commonFont,
            ),
          )
        : null;
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
        return example.tamil ??
            example.hindi ??
            example.telugu ??
            example.malayalam;
    }
  }
}
