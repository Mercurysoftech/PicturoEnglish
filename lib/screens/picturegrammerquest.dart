import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:picturo_app/screens/grammerquestscreen.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/screens/widgets/commons.dart';

import '../cubits/games_cubits/quest_game/quest_game_qtn_list_cubit.dart';
import '../cubits/get_coins_cubit/coins_cubit.dart';
import '../utils/common_app_bar.dart';

class PictureGrammarQuestScreen extends StatefulWidget {
  final String? title;

  const PictureGrammarQuestScreen({super.key, this.title});

  @override
  State<PictureGrammarQuestScreen> createState() => _PictureGrammarQuestScreenState();
}

class _PictureGrammarQuestScreenState extends State<PictureGrammarQuestScreen> {
  final double progress = 0;

  @override
  void initState() {
    context.read<GrammarQuestCubit>().fetchGrammarQuestions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title:"Picture Grammar Quest" ,isBackbutton: true,),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Scrollbar(thickness: 4,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF49329A)),
                            minHeight: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A2D91)),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
          BlocBuilder<GrammarQuestCubit, GrammarQuestState>(
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final question = levels[index];
                      final bool locked = index == 0
                          ? false
                          : !(levels[index - 1].completed);// only first unlocked
                      return GestureDetector(
                        onTap: () async{
                          final int coinCount=  await context.read<CoinCubit>().getCoin();
                          if (!locked && coinCount > 0) {
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
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => GrammarQuestScreen( index: index,questions: levels,level:levels[index].level,questId: question.id,title: question.gameQus),
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
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 20),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: locked ? Colors.grey[300] : Colors.white,
                            borderRadius: BorderRadius.circular(10),
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
                              const SizedBox(height: 10,),
                              if (locked)
                                Icon(Icons.lock, color: Colors.white),
                              if (!locked)
                                (levels[index].completed)?Icon(Icons.check_circle,color: Colors.green,):Icon(Icons.question_mark_outlined, color: Colors.red),
                              const SizedBox(height: 10,),
                              Expanded(
                                child: Text(
                                  "Level ${index + 1}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Poppins Regular',
                                    color: locked ? Colors.black38 : Colors.black,
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
}