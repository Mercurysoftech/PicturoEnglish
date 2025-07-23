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
  context.read<DalLevelUpdateCubit>().getLevel();
  super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: CommonAppBar(title:"${widget.title} Levels",isBackbutton: true,),
      body: BlocBuilder<ProgressCubit, ProgressState>(
  builder: (context, progresState) {
    if(progresState is ProgressLoaded){
      final percentage = (progresState.progress * 100).toInt();
      return (percentage<100)?
      GameLockedScreen(percentage: percentage,)
          :
      BlocBuilder<DragLearnCubit, DragLearnState>(
        builder: (context, state) {
          if (state is DragLearnLoaded) {
            Data? data = widget.data;
            return BlocBuilder<DalLevelUpdateCubit, DalLevelUpdateState>(
              builder: (context, levelState) {
                if(levelState is DalLevelUpdateLoaded){
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
                          final isCompleted = level?.completed??false;
                          final hasEnoughQuestions = (level?.questions?.length ?? 0) >= 5;

                          if (!hasEnoughQuestions) return SizedBox();

                          // Check if all previous levels are completed
                          final isEnabled = index == 0 || (data!.levels!.take(index).every((lvl) => lvl.completed ?? false));

                          return InkWell(
                            onTap: isEnabled
                                ? () async{
                              final int coinCount= await  context.read<CoinCubit>().getCoin();
                              if (isEnabled && coinCount > 0) {
                                showDialog(
                                    context: context,
                                    builder: (context){
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10)
                                        ),
                                        backgroundColor: Colors.white,
                                        title: Text("Are you Sure want Start",style: TextStyle(fontSize: 16,),textAlign: TextAlign.center,),
                                        content: Text("Every level use 1 coin",textAlign: TextAlign.center,),
                                        actions: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                  onPressed: (){
                                                    Navigator.pop(context);
                                                  },
                                                  style: ButtonStyle(
                                                    padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20)),
                                                  ),
                                                  child: Text("Cancel")
                                              ),
                                              SizedBox(
                                                child: TextButton(
                                                    style: ButtonStyle(
                                                        padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20)),
                                                        backgroundColor: WidgetStateProperty.all(Color(0xFF49329A))
                                                    ),
                                                    onPressed: ()async{
                                                      print("sdcsdlkcsdcs;dc");

                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => DragAndLearnApp(preLevels:data?.levels,levelIndex: index,topicId: data?.topicId,bookId: widget.bookId,level: level),
                                                        ),
                                                      );



                                                    },
                                                    child: Text(" Start",style: TextStyle(color: Colors.white ),)
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      );
                                    }
                                );
                              }else if(coinCount <=0){
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
                    ),
                  );
                }else{
                  return SizedBox();
                }

              },
            );
          } else if (state is DragLearnLoading) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Center(child: Text("Something went wrong. Please try again.",style: TextStyle(fontFamily: AppConstants.commonFont,),));
          }
        },
      );
    }else{
      return Center(child: CircularProgressIndicator());
    }

  },
),


    );
  }
}

class GameLockedScreen extends StatelessWidget {
  const GameLockedScreen({super.key, required this.percentage});
  final int percentage;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F5FF),
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF49329A),
                ),
              ),
              Text(
                "You have Completed ${percentage}/100",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF49329A),
                ),
              ),
              SizedBox(height: 12),
              Text(
                "You can'ts play the game untill you readed all the things properly... Because we wants you be smart 🧠 before be fun 🤩",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
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
