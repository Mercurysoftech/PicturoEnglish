import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/cubits/drag_and_learn_cubit/drag_and_learn_cubit.dart';

import '../../models/dragand_learn_model.dart';
import '../../utils/common_app_bar.dart';
import '../../utils/common_file.dart';
import '../dragandlearnpage.dart';

class DragLearnPage extends StatefulWidget {
  const DragLearnPage({super.key,required this.bookId,required this.data, required this.title});
  final int bookId;
  final Data? data;
  final String title;

  @override
  State<DragLearnPage> createState() => _DragLearnPageState();
}

class _DragLearnPageState extends State<DragLearnPage> {


@override
  void initState() {
  context.read<DragLearnCubit>().fetchDragLearnData(bookId:widget.bookId);
  super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: CommonAppBar(title:"${widget.title} Levels",isBackbutton: true,),
      body: BlocBuilder<DragLearnCubit, DragLearnState>(
        builder: (context, state) {
          if (state is DragLearnLoaded) {
            Data? data = widget.data;

            return Padding(
              padding: const EdgeInsets.all(12.0),
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
                  final isCompleted = level?.completed??false;
                  final hasEnoughQuestions = (level?.questions?.length ?? 0) >= 5;

                  if (!hasEnoughQuestions) return SizedBox();

                  // Check if all previous levels are completed
                  final isEnabled = index == 0 || (data!.levels!.take(index).every((lvl) => lvl.completed ?? false));

                  return InkWell(
                    onTap: isEnabled
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DragAndLearnApp(preLevels:data?.levels,levelIndex: index,topicId: data?.topicId,bookId: widget.bookId,level: level),
                        ),
                      );
                    }
                        : null,
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
                },

              ),
            );
          } else if (state is DragLearnLoading) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Center(child: Text("Something went wrong. Please try again.",style: TextStyle(fontFamily: AppConstants.commonFont,),));
          }
        },
      ),


    );
  }
}
