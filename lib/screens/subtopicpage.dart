// subtopic_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/screens/widgets/cat_progress_bar_widget.dart';
import 'package:picturo_app/screens/widgets/subscription_dialog.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/screens/learnwordspage.dart';
import 'package:picturo_app/utils/common_file.dart';
import 'package:shimmer/shimmer.dart';
import '../cubits/content_view_per_get/content_view_percentage_cubit.dart';
import '../cubits/get_sub_topics_list/get_sub_topics_list_cubit.dart';
import '../cubits/get_topics_list_cubit/get_topic_list_cubit.dart';
import '../main.dart';
import '../responses/questions_response.dart';
import '../utils/common_app_bar.dart';

class SubtopicPage extends StatefulWidget {
  final String? title;
  final int? topicId;
  final int? bookId;
  final int? paramsTopicId;

  const SubtopicPage(
      {super.key, this.paramsTopicId, this.title, this.topicId, this.bookId});

  @override
  State<SubtopicPage> createState() => _SubtopicPageState();
}

class _SubtopicPageState extends State<SubtopicPage> {
  bool _hasShownDialog = false;
  bool _isSubscribePlan = false;

  @override
  void initState() {
    super.initState();
    context.read<SubtopicCubit>().fetchQuestions(widget.topicId!);
    context.read<ProgressCubit>().fetchProgress(
          isFromTopic: false,
          bookId: widget.bookId ?? 0,
          topicId: widget.topicId ?? 0,
        );
  }

  void _checkAndShowDialog(ProgressState progressState) {
    if (progressState is ProgressLoaded &&
        progressState.shouldShowSubscriptionDialog &&
        !_hasShownDialog) {
      _hasShownDialog = true;
      _isSubscribePlan = progressState.isSubscribePlan;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        SubscriptionDialog.show(context);
      });
    } else if (progressState is ProgressLoaded) {
      _isSubscribePlan = progressState.isSubscribePlan;
    }
  }

  bool _shouldBlockQuestion(int index, int totalCount) {
    // Subscribed users can access everything
    if (_isSubscribePlan) return false;
    // Non-subscribed users can only access the first 10% of contents
    final int accessibleCount = (totalCount * 0.10).ceil().clamp(1, totalCount);
    return index >= accessibleCount;
  }

  // void _handleQuestionTap(Question question) {
  //   // Check if user should be blocked
  //   if (_shouldBlockNavigation) {
  //     SubscriptionDialog.show(context);
  //     return;
  //   }

  //   // Allow navigation if user is subscribed or not a free user
  //   _navigateToLearnWords(question);
  // }

  Future<void> _navigateToLearnWords(Question question) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearnWordsPage(
          topicId: widget.topicId!,
          bookId: widget.bookId.toString(),
          questionId: question.id ?? 0,
          quesImage: question.qusImage ?? '',
        ),
      ),
    );

    // Mark as read
    await context.read<SubtopicCubit>().markQuestionAsRead(
          context,
          question.id ?? 0,
          widget.topicId!,
          widget.bookId!,
        );

    // Refresh topics list to update completion status
    await context.read<TopicCubit>().fetchTopics(widget.bookId!);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context
            .read<TopicCubit>()
            .fetchTopics(widget.bookId ?? 0, forceRefresh: true);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CommonAppBar(
          onBackButtonTap: () {
            Navigator.pop(context);
            context
                .read<TopicCubit>()
                .fetchTopics(widget.bookId ?? 0, forceRefresh: true);
          },
          title: widget.title ?? '',
          isBackbutton: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProgressBarWidget(
              bookId: widget.bookId ?? 0,
              topicId: widget.topicId ?? 0,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocConsumer<ProgressCubit, ProgressState>(
                listener: (context, progressState) {
                  _checkAndShowDialog(progressState);
                },
                builder: (context, progressState) {
                  return BlocBuilder<SubtopicCubit, SubtopicState>(
                    builder: (context, state) {
                      if (state is SubtopicProgressiveLoading) {
                        return Column(
                          children: [
                            LinearProgressIndicator(
                              value: state.loadedQuestions.length /
                                  state.totalCount,
                              minHeight: 3,
                              color: const Color(0xFF49329A),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: state.loadedQuestions.length,
                                itemBuilder: (context, index) {
                                  return optionTile(
                                    context,
                                    index + 1,
                                    state.loadedQuestions[index],
                                    widget.topicId!,
                                    widget.bookId!,
                                    index: index,
                                    totalCount: state.totalCount,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      } else if (state is SubtopicError) {
                        return Center(child: Text(state.message));
                      } else if (state is SubtopicLoaded) {
                        if (state.questions.isEmpty) {
                          return const Center(
                            child:
                                Text('No questions available for this topic'),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Scrollbar(
                            child: ListView.builder(
                              key: PageStorageKey(
                                  'subtopic_list_${widget.topicId}'),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: state.questions.length,
                              itemBuilder: (context, index) {
                                return optionTile(
                                  context,
                                  index + 1,
                                  state.questions[index],
                                  widget.topicId!,
                                  widget.bookId!,
                                  index: index,
                                  totalCount: state.questions.length,
                                );
                              },
                            ),
                          ),
                        );
                      } else {
                        return _buildInitialLoadingContent();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialLoadingContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF49329A).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF49329A)),
                      strokeWidth: 8,
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.menu_book,
                      color: Color(0xFF49329A),
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Preparing Contents',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF49329A),
                fontWeight: FontWeight.bold,
                fontFamily: AppConstants.commonFont,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading questions...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: AppConstants.commonFont,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget optionTile(BuildContext context, int number, Question question,
      int topicId, int bookId,
      {required int index, required int totalCount}) {
    final bool isBlocked = _shouldBlockQuestion(index, totalCount);

    return Opacity(
      opacity: isBlocked ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isBlocked
            ? () => SubscriptionDialog.show(context)
            : () => _handleQuestionTap(question, topicId, bookId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isBlocked
                ? Colors.grey[100]
                : (question.read ?? false)
                    ? Colors.green[100]
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isBlocked ? Colors.grey[300]! : Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isBlocked
                        ? Colors.grey
                        : (question.read ?? false)
                            ? Colors.green
                            : const Color(0xFF49329A),
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
                    color: isBlocked
                        ? Colors.grey
                        : (question.read ?? false)
                            ? Colors.green
                            : const Color(0xFF49329A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  capitalizeFirstLetter(question.question ?? ''),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppConstants.commonFont,
                    color: isBlocked ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
              if (!isBlocked && (question.read ?? false))
                const Icon(Icons.check_circle, color: Colors.green),
              if (isBlocked)
                Icon(Icons.lock, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleQuestionTap(
      Question question, int topicId, int bookId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearnWordsPage(
          topicId: topicId,
          bookId: bookId.toString(),
          questionId: question.id ?? 0,
          quesImage: question.qusImage ?? '',
        ),
      ),
    );

    // Mark as read (this will happen even for replay)
    if (mounted) {
      await context
          .read<SubtopicCubit>()
          .markQuestionAsRead(context, question.id ?? 0, topicId, bookId);

      // Refresh topics list to update completion status
      if (mounted) {
        await context
            .read<TopicCubit>()
            .fetchTopics(bookId, forceRefresh: true);
      }
    }
  }
}
