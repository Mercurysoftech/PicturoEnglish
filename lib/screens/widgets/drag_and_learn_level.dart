import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:picturo_app/cubits/content_view_per_get/content_view_percentage_cubit.dart';
import 'package:picturo_app/cubits/dal_level_update_cubit/dal_level_update_cubit.dart';
import 'package:picturo_app/cubits/drag_and_learn_cubit/drag_and_learn_cubit.dart';

import '../../cubits/bottom_navigator_index_cubit.dart';
import '../../cubits/get_coins_cubit/coins_cubit.dart';
import '../../models/dragand_learn_model.dart';
import '../../utils/common_app_bar.dart';
import '../../utils/common_file.dart';
import '../dragandlearnpage.dart';
import 'commons.dart';

class DragLearnPage extends StatefulWidget {
  const DragLearnPage({
    super.key,
    required this.bookId,
    required this.data,
    required this.title,
  });
  
  final int bookId;
  final Data? data;
  final String title;

  @override
  State<DragLearnPage> createState() => _DragLearnPageState();
}

class _DragLearnPageState extends State<DragLearnPage> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Only fetch if not already loaded (will use cache instantly!)
    if (!_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DragLearnCubit>().fetchDragLearnData(bookId: widget.bookId);
        context.read<DalLevelUpdateCubit>().getLevel();
      });
      _hasInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: CommonAppBar(
        title: "${widget.title} Levels",
        isBackbutton: true,
      ),
      body: BlocBuilder<ProgressCubit, ProgressState>(
        builder: (context, progresState) {
          if (progresState is ProgressLoaded) {
            final percentage = (progresState.progress * 100).toInt();
            return (percentage < 100)
                ? GameLockedScreen(percentage: percentage)
                : BlocBuilder<DragLearnCubit, DragLearnState>(
                    buildWhen: (previous, current) {
                      // Only rebuild when we actually have new data
                      if (previous is DragLearnLoaded && current is DragLearnLoading) {
                        return false; // Keep showing cached data
                      }
                      return true;
                    },
                    builder: (context, state) {
                      if (state is DragLearnLoaded) {
                        // Get the latest data for this topic
                        Data? data = state.data.data?.firstWhere(
                          (d) => d.topicId == widget.data?.topicId,
                          orElse: () => widget.data ?? Data(),
                        );

                        return BlocBuilder<DalLevelUpdateCubit, DalLevelUpdateState>(
                          builder: (context, levelState) {
                            if (levelState is DalLevelUpdateLoaded) {
                              return _buildLevelGrid(data);
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        );
                      } else if (state is DragLearnLoading) {
                        return Center(child: CircularProgressIndicator());
                      } else {
                        return Center(
                          child: Text(
                            "Something went wrong. Please try again.",
                            style: TextStyle(
                              fontFamily: AppConstants.commonFont,
                            ),
                          ),
                        );
                      }
                    },
                  );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildLevelGrid(Data? data) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Scrollbar(
        child: GridView.builder(
          itemCount: data?.levels?.length ?? 0,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final level = data?.levels?[index];
            final isCompleted = level?.completed ?? false;
            final hasEnoughQuestions = (level?.questions?.length ?? 0) >= 3;

            if (!hasEnoughQuestions) return SizedBox();

            // Check if all previous levels are completed
            final isEnabled = index == 0 ||
                (data!.levels!.take(index).every((lvl) => lvl.completed ?? false));

            return _buildLevelCard(
              data: data,
              level: level,
              index: index,
              isCompleted: isCompleted,
              isEnabled: isEnabled,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelCard({
    required Data? data,
    required Levels? level,
    required int index,
    required bool isCompleted,
    required bool isEnabled,
  }) {
    return InkWell(
      onTap: isEnabled ? () => _handleLevelTap(data, level, index) : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? Colors.white
                  : isEnabled
                      ? Colors.blue
                      : Colors.grey.shade300,
              width: 2,
            ),
            color: isCompleted
                ? Colors.green
                : isEnabled
                    ? Colors.white
                    : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : isEnabled
                        ? Icons.play_circle_outline
                        : Icons.lock_outline,
                color: isCompleted
                    ? Colors.white
                    : isEnabled
                        ? Colors.blue
                        : Colors.grey,
                size: 36,
              ),
              SizedBox(height: 12),
              Text(
                "Level ${level?.level}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? Colors.white
                      : isEnabled
                          ? Colors.blue.shade700
                          : Colors.black54,
                  fontFamily: AppConstants.commonFont,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLevelTap(Data? data, Levels? level, int index) async {
    final int coinCount = await context.read<CoinCubit>().getCoin();
    
    if (!mounted) return;

    // Uncomment this to enable coin check
    // if (coinCount <= 0) {
    //   Fluttertoast.showToast(msg: 'Not enough Coin');
    //   return;
    // }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white,
        title: Text(
          "Are you Sure want Start the Game?",
          style: TextStyle(
            fontSize: 16,
            fontFamily: AppConstants.commonFont,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: TextStyle(fontFamily: AppConstants.commonFont),
                ),
              ),
              TextButton(
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(horizontal: 20),
                  ),
                  backgroundColor: WidgetStateProperty.all(Color(0xFF49329A)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  " Start",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: AppConstants.commonFont,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DragAndLearnApp(
            preLevels: data?.levels,
            levelIndex: index,
            topicId: data?.topicId,
            bookId: widget.bookId,
            level: level,
          ),
        ),
      );

      if (mounted) {
        // Check if level was completed (you can pass this back from DragAndLearnApp)
        final wasCompleted = result is Map && result['completed'] == true;
        
        if (wasCompleted) {
          // Update cache immediately with completion status
          await context.read<DragLearnCubit>().updateLevelCompletion(
                bookId: widget.bookId,
                topicId: data?.topicId ?? 0,
                levelIndex: index,
                completed: true,
              );
        } else {
          // Force refresh to get latest data from API
          await context.read<DragLearnCubit>().fetchDragLearnData(
                bookId: widget.bookId,
                forceRefresh: true,
              );
        }
        
        // Refresh level state
        context.read<DalLevelUpdateCubit>().getLevel();
      }
    }
  }
}

class GameLockedScreen extends StatelessWidget {
  const GameLockedScreen({super.key, required this.percentage});
  final int percentage;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 60, color: Color(0xFF49329A)),
              SizedBox(height: 20),
              Text(
                "Game is unopen 😕",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppConstants.commonFont,
                  color: Color(0xFF49329A),
                ),
              ),
              Text(
                "You have Completed ${percentage}/100",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppConstants.commonFont,
                  color: Color(0xFF49329A),
                ),
              ),
              SizedBox(height: 12),
              Text(
                "You can't play the game until you read all the things properly... Because we want you to be smart 🧠 before being fun 🤩",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppConstants.commonFont,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  context.read<BottomNavigatorIndexCubit>().onChageIndex(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF49329A),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Read Contents",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: AppConstants.commonFont,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}