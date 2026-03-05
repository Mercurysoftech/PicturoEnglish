import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:picturo_app/responses/grammar_quest_response.dart';
import 'package:picturo_app/screens/grammerquestscreen.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/screens/widgets/commons.dart';
import 'package:picturo_app/screens/widgets/subscription_dialog.dart';

import '../cubits/games_cubits/quest_game/quest_game_qtn_list_cubit.dart';
import '../cubits/get_coins_cubit/coins_cubit.dart';
import '../utils/common_app_bar.dart';

class PictureGrammarQuestScreen extends StatefulWidget {
  final String? title;

  const PictureGrammarQuestScreen({super.key, this.title});

  @override
  State<PictureGrammarQuestScreen> createState() =>
      _PictureGrammarQuestScreenState();
}

class _PictureGrammarQuestScreenState extends State<PictureGrammarQuestScreen> {
  final double progress = 0;
  bool _hasShownDialog = false;
  bool _isFreehitUser = false;
  bool _isSubscribePlan = false;

  @override
  void initState() {
    context.read<GrammarQuestCubit>().fetchGrammarQuestions();
    super.initState();
  }

  void _checkAndShowDialog(GrammarQuestState questState) {
    if (questState is GrammarQuestLoaded &&
        questState.shouldShowSubscriptionDialog &&
        !_hasShownDialog) {
      _hasShownDialog = true;
      _isFreehitUser = questState.isFreeHitUser;
      _isSubscribePlan = questState.isSubscribePlan;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SubscriptionDialog.show(context);
      });
    } else if (questState is GrammarQuestLoaded) {
      _isFreehitUser = questState.isFreeHitUser;
      _isSubscribePlan = questState.isSubscribePlan;
    }
  }

  bool _shouldBlockLevel(GrammarQuestion question) {
    // Free users can access completed levels (for replay)
    // But are blocked from incomplete levels
    return _isFreehitUser && !_isSubscribePlan && !question.completed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(
        title: "Picture Grammar Quest",
        isBackbutton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Scrollbar(
          thickness: 4,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                BlocConsumer<GrammarQuestCubit, GrammarQuestState>(
                  listener: (context, state) {
                    _checkAndShowDialog(state);
                  },
                  builder: (context, state) {
                    if (state is GrammarQuestLoading) {
                      return Center(child: CircularProgressIndicator());
                    } else if (state is GrammarQuestFailed) {
                      return Center(child: Text("Error: ${state.message}"));
                    } else if (state is GrammarQuestLoaded) {
                      final levels = state.questions;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.70,
                          ),
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          itemCount: levels.length,
                          itemBuilder: (context, index) {
                            final question = levels[index];
                            final bool progressionLocked = index == 0
                                ? false
                                : !(levels[index - 1].completed);
                            
                            // Check if this specific level is blocked by subscription
                            final bool subscriptionLocked = _shouldBlockLevel(question);

                            return GestureDetector(
                              onTap: () => _handleLevelTap(
                                context,
                                index,
                                question,
                                levels,
                                progressionLocked,
                              ),
                              child: Container(
                                margin: EdgeInsets.only(bottom: 20),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: progressionLocked
                                      ? Colors.grey[300]
                                      : subscriptionLocked
                                          ? Colors.orange[50]
                                          : question.completed
                                              ? Colors.green[50]
                                              : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: subscriptionLocked
                                      ? Border.all(
                                          color: Colors.orange,
                                          width: 2,
                                        )
                                      : question.completed
                                          ? Border.all(
                                              color: Colors.green,
                                              width: 2,
                                            )
                                          : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 10),
                                    if (subscriptionLocked)
                                      Icon(Icons.lock, color: Colors.orange, size: 32)
                                    else if (progressionLocked)
                                      Icon(Icons.lock, color: Colors.white, size: 32)
                                    else if (levels[index].completed)
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 32,
                                      )
                                    else
                                      Icon(
                                        Icons.play_circle_outline,
                                        color: Colors.blue,
                                        size: 32,
                                      ),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: Text(
                                        "Level ${index + 1}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Poppins Regular',
                                          color: subscriptionLocked
                                              ? Colors.orange
                                              : progressionLocked
                                                  ? Colors.black38
                                                  : question.completed
                                                      ? Colors.green
                                                      : Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (subscriptionLocked)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "Subscribe",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else if (question.completed)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "Replay",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLevelTap(
    BuildContext context,
    int index,
    GrammarQuestion question,
    List<GrammarQuestion> levels,
    bool progressionLocked,
  ) async {
    // Check if user should be blocked by subscription (only for incomplete levels)
    if (_shouldBlockLevel(question)) {
      SubscriptionDialog.show(context);
      return;
    }

    // Check if level is locked by progression (previous level not completed)
    if (progressionLocked) {
      Fluttertoast.showToast(msg: 'Complete previous level first');
      return;
    }

    final int coinCount = await context.read<CoinCubit>().getCoin();
    
    if (coinCount <= 0) {
      Fluttertoast.showToast(msg: 'Not enough Coin');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white,
          title: Text(
            question.completed
                ? "Replay this level?"
                : "Are you Sure want Start the Game?",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                  child: Text("Cancel"),
                ),
                SizedBox(
                  child: TextButton(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        EdgeInsets.symmetric(horizontal: 20),
                      ),
                      backgroundColor: WidgetStateProperty.all(
                        Color(0xFF49329A),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GrammarQuestScreen(
                            imageUrl: levels[index].imagePath,
                            index: index,
                            questions: levels,
                            level: levels[index].level,
                            questId: question.id,
                            title: question.gameQus,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      question.completed ? "Replay" : "Start",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }
}