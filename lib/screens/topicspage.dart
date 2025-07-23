import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/responses/topics_response.dart'; // Import your TopicsResponse model
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/services/api_service.dart'; // Import your API service
import 'package:picturo_app/screens/subtopicpage.dart';
import 'package:picturo_app/utils/cached_network_image.dart';

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
  int? selectedIndex; // Track the selected item

  @override
  void initState() {
    super.initState();
    context.read<TopicCubit>().fetchTopics(widget.topicId);
  }

  // Future<void> fetchTopicsAndUpdateUI() async {
  //   try {
  //     // Fetch the topics data
  //     final apiService = await ApiService.create();
  //     TopicsResponse topicsResponse = await apiService.fetchTopics(widget.topicId); // Replace 1 with the actual book ID
  //
  //     // Update the state with the fetched topics
  //
  //     setState(() {
  //       _topics = topicsResponse.data.map((topic) {
  //         return {
  //           'title': topic.topicsName, // Use topics_name from the response
  //           'id': topic.id, // Use id from the response
  //           'image': topic.topicsImage, // Use a default image
  //         };
  //       }).toList();
  //       _isLoading = false; // Data fetching is complete
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = "Error fetching topics: $e"; // Store the error message
  //       _isLoading = false; // Data fetching failed
  //     });
  //     print("Error fetching topics: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // Navigate to the desired page instead of popping the current page
       Navigator.pop(context);
        return false; // Prevent default back button behavior
      },
      child:
    Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: CommonAppBar(title:widget.title,isBackbutton: true,),
      body: BlocBuilder<TopicCubit, TopicState>(
  builder: (context, state) {

    if(state is TopicLoaded){

      List<Map<String,dynamic>> topics=state.topics;
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
          padding: const EdgeInsets.symmetric(horizontal: 14.0,vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Categories", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,fontFamily: 'Poppins Regular', color: Colors.black)),
              SizedBox(height: 16),
              Expanded(
                child:  Scrollbar(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: topics.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                            // Navigate to a new screen when an item is clicked
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubtopicPage(bookId: widget.topicId,
                                    title: topics[index]['title']!,
                                    topicId: topics[index]['id']
                                ),
                              ),
                            );
                          },
                          child: TopicCard(
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
    }else{
      return Center(child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator())) ;
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

  const TopicCard({
    super.key,
    required this.title,
    required this.image,
    this.isSelected = false,
  });

  @override
  State<TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<TopicCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150, // fixed height for consistency
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: widget.isSelected ? Border.all(color: Colors.green, width: 2) : null,
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
          // Background image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImageWidget(
              imageUrl: "https://picturoenglish.com/admin/${widget.image}",
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
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
                capitalizeFirstLetter(widget.title=="Action verb"?"Action Verbs":widget.title),
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
          // if (widget.isSelected)
          //   Positioned(
          //     top: 6,
          //     right: 6,
          //     child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
          //   ),
        ],
      ),
    );
  }
}


