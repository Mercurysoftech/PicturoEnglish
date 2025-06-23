import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:picturo_app/cubits/drag_and_learn_cubit/drag_and_learn_cubit.dart';

import '../../cubits/get_coins_cubit/coins_cubit.dart';
import '../../models/dragand_learn_model.dart';
import '../../utils/common_app_bar.dart';
import '../../utils/common_file.dart';
import '../dragandlearnpage.dart';
import 'commons.dart';

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

                  final isEnabled = index == 0 || (data!.levels!.take(index).every((lvl) => lvl.completed ?? false));

                  return InkWell(
                    onTap: isEnabled
                        ? () async {
                      final int coinCount =
                      await context.read<CoinCubit>().getCoin();
                      if (coinCount > 0) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10)),
                              backgroundColor: Colors.white,
                              title: const Text(
                                "Are you Sure want Start",
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              content: const Text(
                                "Every level use 1 coin",
                                textAlign: TextAlign.center,
                              ),
                              actions: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: ButtonStyle(
                                        padding: WidgetStateProperty.all(
                                            const EdgeInsets.symmetric(
                                                horizontal: 20)),
                                      ),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      style: ButtonStyle(
                                        padding: WidgetStateProperty.all(
                                            const EdgeInsets.symmetric(
                                                horizontal: 20)),
                                        backgroundColor:
                                        WidgetStateProperty.all(
                                            const Color(0xFF49329A)),
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(context);

                                        final result =
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DragAndLearnApp(
                                                  preLevels: data?.levels,
                                                  levelIndex: index,
                                                  topicId: data?.topicId,
                                                  bookId: widget.bookId,
                                                  level: level,
                                                ),
                                          ),
                                        );

                                        context
                                            .read<CoinCubit>()
                                            .useCoin(1);

                                        if (result == true) {
                                          // Refresh data after level completion
                                          context
                                              .read<DragLearnCubit>()
                                              .fetchDragLearnData(
                                              bookId:
                                              widget.bookId);
                                          Fluttertoast.showToast(
                                              msg:
                                              'Level Completed! Next level unlocked.');
                                        }
                                      },
                                      child: const Text(
                                        " Start",
                                        style: TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            );
                          },
                        );
                      } else {
                        Fluttertoast.showToast(msg: 'Not enough Coin');
                      }
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
