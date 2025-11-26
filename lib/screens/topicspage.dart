import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/responses/topics_response.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/screens/subtopicpage.dart';
import 'package:picturo_app/utils/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../cubits/get_topics_list_cubit/get_topic_list_cubit.dart';
import '../main.dart';
import '../utils/common_app_bar.dart';
import '../utils/common_file.dart';

class TopicsScreen extends StatefulWidget {
  final String title;
  final int topicId;
  const TopicsScreen({super.key, required this.title, required this.topicId});

  @override
  _TopicsScreenState createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  int? selectedIndex;
  Map<String, dynamic>? _lastSelectedTopic;

  @override
  void initState() {
    super.initState();
    context.read<TopicCubit>().fetchTopics(widget.topicId);
    _loadLastSelectedTopic();
  }

  Future<void> _loadLastSelectedTopic() async {
    final lastTopic = await TopicSelectionHelper.getLastSelectedTopic();
    if (lastTopic != null && mounted) {
      setState(() {
        _lastSelectedTopic = lastTopic;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFE0F7FF),
        appBar: CommonAppBar(
          title: widget.title,
          isBackbutton: true,
        ),
        body: BlocBuilder<TopicCubit, TopicState>(
          builder: (context, state) {
            if (state is TopicLoaded) {
              List<Map<String, dynamic>> topics = state.topics;

              // Find if any topic matches the last selected topic
              if (_lastSelectedTopic != null && selectedIndex == null) {
                for (int i = 0; i < topics.length; i++) {
                  if (topics[i]['id'] == _lastSelectedTopic!['topicId']) {
                    selectedIndex = i;
                    break;
                  }
                }
              }
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFE0F7FF),
                      Color(0xFFEAE4FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14.0, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Categories",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins Regular',
                              color: Colors.black)),
                      SizedBox(height: 16),
                      Expanded(
                        child: Scrollbar(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: GridView.builder(
                              shrinkWrap: true,
                              itemCount: topics.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.85,
                              ),
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedIndex = index;
                                    });

                                    TopicSelectionHelper.saveLastSelectedTopic(
                                      topics[index]['id'],
                                      widget.topicId,
                                      topics[index]['title'],
                                    );
                                    
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SubtopicPage(
                                            paramsTopicId: widget.topicId,
                                            bookId: widget.topicId,
                                            title: topics[index]['title']!,
                                            topicId: topics[index]['id']),
                                      ),
                                    );
                                  },
                                  child: TopicCard(
                                    isCompleted: topics[index]['isCompleted'],
                                    title: topics[index]['title']!,
                                    image: topics[index]['image']!,
                                    isSelected: selectedIndex == index,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Center(
                  child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator()));
            }
          },
        ),
      ),
    );
  }
}

class TopicCard extends StatefulWidget {
  final String title;
  final String image;
  final bool isSelected;
  final bool isCompleted;

  const TopicCard({
    super.key,
    required this.title,
    required this.image,
    required this.isCompleted,
    this.isSelected = false,
  });

  @override
  State<TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<TopicCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: (widget.isCompleted || widget.isSelected)
            ? Border.all(color: Colors.green, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background image with cached network image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl:
                        'https://picturoenglish.com/admin/${widget.image}',
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                    httpHeaders: {
                      'Accept': 'image/*',
                    },
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        color: Colors.white,
                        height: double.infinity,
                        width: double.infinity,
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print("Image load error: $error for URL: $url");
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 30, color: Colors.red),
                            SizedBox(height: 8),
                            Text(
                              'Image failed to load',
                              style: TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                    memCacheWidth: 400,
                    memCacheHeight: 400,
                    maxWidthDiskCache: 400,
                    maxHeightDiskCache: 400,
                    fadeInDuration: Duration(milliseconds: 200),
                    fadeOutDuration: Duration(milliseconds: 200),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Text('No image available'),
                    ),
                  ),
          ),

          // Semi-transparent overlay for text readability
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // Title text
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                capitalizeFirstLetter(widget.title == "Action verb"
                    ? "Action Verbs"
                    : widget.title),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppConstants.commonFont,
                  color: Colors.white,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Check icon if selected
          if (widget.isCompleted)
            Positioned(
              top: 6,
              right: 6,
              child:
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
        ],
      ),
    );
  }
}

class TopicSelectionHelper {
  static const String _lastSelectedTopicKey = 'last_selected_topic';

  static Future<void> saveLastSelectedTopic(
      int topicId, int bookId, String title) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSelectedTopicKey, '$topicId,$bookId,$title');
  }

  static Future<Map<String, dynamic>?> getLastSelectedTopic() async {
    final prefs = await SharedPreferences.getInstance();
    final topicData = prefs.getString(_lastSelectedTopicKey);

    if (topicData != null) {
      final parts = topicData.split(',');
      if (parts.length == 3) {
        return {
          'topicId': int.parse(parts[0]),
          'bookId': int.parse(parts[1]),
          'title': parts[2],
        };
      }
    }
    return null;
  }

  static Future<void> clearLastSelectedTopic() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSelectedTopicKey);
  }
}
