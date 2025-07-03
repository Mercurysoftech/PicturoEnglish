// subtopic_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/screens/widgets/cat_progress_bar_widget.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/screens/learnwordspage.dart';
import 'package:picturo_app/utils/common_file.dart';
import '../cubits/content_view_per_get/content_view_percentage_cubit.dart';
import '../cubits/get_sub_topics_list/get_sub_topics_list_cubit.dart';
import '../main.dart';
import '../responses/questions_response.dart';
import '../utils/common_app_bar.dart';


class SubtopicPage extends StatefulWidget {
  final String? title;
  final int? topicId;
  final int? bookId;

  const SubtopicPage({super.key, this.title, this.topicId, this.bookId});

  @override
  State<SubtopicPage> createState() => _SubtopicPageState();
}

class _SubtopicPageState extends State<SubtopicPage> {
  @override
  void initState() {
    // TODO: implement initState
    context.read<SubtopicCubit>().fetchQuestions(widget.topicId!);
    context.read<ProgressCubit>().fetchProgress(bookId: widget.bookId??0, topicId: widget.topicId??0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: CommonAppBar(title:widget.title??'',isBackbutton: true,),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressBarWidget(bookId: widget.bookId ?? 0, topicId: widget.topicId ?? 0),
            const SizedBox(height: 20),
            Expanded(child: BlocBuilder<SubtopicCubit, SubtopicState>(

              builder: (context, state) {
                if (state is SubtopicLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SubtopicError) {
                  return _buildError(state.message, context);
                } else if (state is SubtopicLoaded) {
                  if (state.questions.isEmpty) {
                    return const Center(child: Text('No questions available for this topic'));
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Scrollbar(
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: state.questions.length,
                        itemBuilder: (context, index) {
                          return optionTile(
                            context,
                            index + 1,
                            state.questions[index],
                            widget.topicId!,
                            widget.bookId!,
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  return const SizedBox();
                }
              },
            )),
          ],
        ),
      );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AppBar(
        backgroundColor: const Color(0xFF49329A),
        leading: Padding(
          padding: const EdgeInsets.only(top: 15.0, left: 24.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Row(
            children: [
              Text(
                widget.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins Regular',
                ),
              ),
            ],
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildError(String message, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(fontSize: 16, color: Colors.red)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.read<SubtopicCubit>().fetchQuestions(widget.topicId!),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF49329A),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget optionTile(BuildContext context, int number, Question question, int topicId, int bookId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LearnWordsPage(
              topicId: topicId,
              bookId: bookId.toString(),
              questionId: question.id ?? 0,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (question.read ?? false) ? Colors.green[100] : Colors.white,
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
                  color: (question.read ?? false) ? Colors.green : const Color(0xFF49329A),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppConstants.commonFont,
                  color: (question.read ?? false) ? Colors.green : const Color(0xFF49329A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                capitalizeFirstLetter(question.question ?? ''),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppConstants.commonFont,
                  color: Colors.black87,
                ),
              ),
            ),
            if (question.read ?? false)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
