import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/responses/topics_response.dart'; // Import your TopicsResponse model
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/services/api_service.dart'; // Import your API service
import 'package:picturo_app/screens/subtopicpage.dart';

import '../cubits/get_topics_list_cubit/get_topic_list_cubit.dart';

class TopicsScreen extends StatefulWidget {
  final String title;
  final int topicId;
  const TopicsScreen({super.key, required this.title, required this.topicId});

  @override
  _TopicsScreenState createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  int? selectedIndex; // Track the selected item

  bool _isLoading = true; // Track loading state
  String _errorMessage = ''; // Store error messages

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
        );
        return false; // Prevent default back button behavior
      },
      child:
    Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
                Navigator.pop(context); // Navigate back
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Row(
              children: [
                Text(
                  widget.title,
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
      body: BlocBuilder<TopicCubit, TopicState>(
  builder: (context, state) {
    print("sdjclskcsdc ${state.runtimeType}");
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Categories", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,fontFamily: 'Poppins Regular', color: Colors.black)),
              SizedBox(height: 16),
              Expanded(
                child:  GridView.builder(
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
      decoration: BoxDecoration(
        color: widget.isSelected ? Color(0xFFDDF6D6) : Colors.white,
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
          Center(
            child:
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

            ClipRRect(
            borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        filterQuality: FilterQuality.low,
        useOldImageOnUrlChange: true,
        imageUrl: "https://picturoenglish.com/admin/${widget.image}",
        height: 120,
        width: 125,
        fit: BoxFit.cover,

        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(strokeWidth: 0.7,),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            Icons.broken_image,
            size: 50,
            color: Colors.grey,
          ),
        ),
      ),),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins Medium',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ),
          if (widget.isSelected)
            Positioned(
              top: 4,
              right: 1,
              child: Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
        ],
      ),
    );
  }
}

