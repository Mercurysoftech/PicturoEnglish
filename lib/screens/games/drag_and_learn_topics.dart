import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/responses/topics_response.dart'; // Import your TopicsResponse model
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/services/api_service.dart'; // Import your API service
import 'package:picturo_app/screens/subtopicpage.dart';
import 'package:shimmer/shimmer.dart';

import '../../cubits/drag_and_learn_cubit/drag_and_learn_cubit.dart';
import '../../cubits/get_topics_list_cubit/get_topic_list_cubit.dart';
import '../../models/dragand_learn_model.dart';
import '../../utils/common_app_bar.dart';
import '../../utils/common_file.dart';
import '../widgets/drag_and_learn_level.dart';



class DLGameTopicsPage extends StatefulWidget {
  final String title;
  final int topicId;
  const DLGameTopicsPage({super.key, required this.title, required this.topicId});

  @override
  _DLGameTopicsPageState createState() => _DLGameTopicsPageState();
}

class _DLGameTopicsPageState extends State<DLGameTopicsPage> {
  int? selectedIndex; // Track the selected item



  @override
  void initState() {
    super.initState();
    context.read<DragLearnCubit>().fetchDragLearnData(bookId:widget.topicId);
    context.read<TopicCubit>().fetchTopics(widget.topicId);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return Scaffold(
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
              child: BlocBuilder<DragLearnCubit, DragLearnState>(
                builder: (context, dragLearnState) {

                  if(dragLearnState is DragLearnLoaded){
                    DragAndLearnLevelModel data=dragLearnState.data;
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Categories", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: AppConstants.commonFont, color: Colors.black)),
                          SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              itemCount: topics.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedIndex = index;
                                    });

                                    List<Data>? selectedFiles= data.data?.where((element)=>element.topicId.toString()==topics[index]['id'].toString()).toList();

                                    if(selectedFiles!=null&&selectedFiles.isNotEmpty){
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => DragLearnPage(title: topics[index]['title'],bookId: widget.topicId, data: selectedFiles.first,)),
                                      );
                                    }

                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: TopicCard(
                                      title: topics[index]['title']=="Action verb"?"Action Verbs":topics[index]['title']!,
                                      image: topics[index]['image']!,
                                      isSelected: selectedIndex == index,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }else{
                    return Center(
                      child: SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

  },
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
    );
  }
}
class TopicCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE3FCE5) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(2, 2),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-2, -2),
            blurRadius: 6,
          ),
        ],
        border: Border.all(
          color: isSelected ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: "https://picturoenglish.com/admin/$image",
              height: 70,
              width: 70,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const Icon(
                Icons.broken_image,
                size: 40,
                color: Colors.grey,
              ),
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: AppConstants.commonFont,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: Colors.green, size: 22),
        ],
      ),
    );
  }
}

