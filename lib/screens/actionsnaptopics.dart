import 'package:flutter/material.dart';
import 'package:picturo_app/screens/dragandlearnpage.dart';
import 'package:picturo_app/screens/picturegrammerquest.dart';
import 'package:picturo_app/screens/actionsnappage.dart';

import '../utils/common_app_bar.dart';

class ActionSnapTopicsScreen extends StatefulWidget {
  String? gameName;
  ActionSnapTopicsScreen({super.key, this.gameName});

  @override
  _ActionSnapTopicsScreenState createState() => _ActionSnapTopicsScreenState();
}

class _ActionSnapTopicsScreenState extends State<ActionSnapTopicsScreen> {
  // Simplified topics list with only core grammar elements
  // final List<Map<String, dynamic>> _grammarTopics = [
  //   {
  //     'title': 'Verbs',
  //     'description': 'Action words (run, eat, think)',
  //     'color': Color(0xFF4E7AC7), // Deep blue
  //     'icon': Icons.directions_run,
  //   },
  //   {
  //     'title': 'Adverbs',
  //     'description': 'Modify verbs (quickly, silently)',
  //     'color': Color(0xFF5CB85C), // Fresh green
  //     'icon': Icons.speed,
  //   },
  //   {
  //     'title': 'Adjectives',
  //     'description': 'Describe nouns (happy, blue, large)',
  //     'color': Color(0xFFD9534F), // Warm red
  //     'icon': Icons.format_color_fill,
  //   },
  // ];
  List<String> levels=["run", "walk", "kick", "throw", "hit", "push", "pull", "lift", "drop", "sit",
    "stand", "hug", "kiss", "wave", "scratch", "bend", "dig", "carry", "swing", "drag",
    "quickly", "slowly", "forcefully", "powerfully", "upward", "downward"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: CommonAppBar(title:"${widget.gameName}" ,isBackbutton: true,),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 10),
              child: Text(
                'Core Grammar Topics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF343A40),
                ),
              ),
            ),
            Expanded(
              child:  Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 10),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    final question = levels[index];
                    // final bool locked = index == 0
                    //     ? false
                    //     : !(levels[index - 1].completed);// only first unlocked
                    return GestureDetector(
                      onTap: () async{
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ActionSnapApp(topic: question,)));
                        // final int coinCount=  await context.read<CoinCubit>().getCoin();
                        // if (!locked && coinCount > 0) {
                        //   showDialog(
                        //       context: context,
                        //       builder: (context){
                        //         return AlertDialog(
                        //           shape: RoundedRectangleBorder(
                        //               borderRadius: BorderRadius.circular(10)
                        //           ),
                        //           backgroundColor: Colors.white,
                        //           title: Text("Are you Sure want Start",style: TextStyle(fontSize: 16,),textAlign: TextAlign.center,),
                        //           content: Text("Every level use 1 coin",textAlign: TextAlign.center,),
                        //           actions: [
                        //             Row(
                        //               mainAxisAlignment: MainAxisAlignment.end,
                        //               children: [
                        //                 TextButton(
                        //                     onPressed: (){
                        //                       Navigator.pop(context);
                        //                     },
                        //                     style: ButtonStyle(
                        //                       padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20)),
                        //                     ),
                        //                     child: Text("Cancel")
                        //
                        //                 ),
                        //                 SizedBox(
                        //                   child: TextButton(
                        //                       style: ButtonStyle(
                        //                           padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 20)),
                        //                           backgroundColor: WidgetStateProperty.all(Color(0xFF49329A))
                        //                       ),
                        //                       onPressed: ()async{
                        //                         Navigator.pop(context);
                        //                         Navigator.push(
                        //                           context,
                        //                           MaterialPageRoute(
                        //                             builder: (context) => GrammarQuestScreen(imageUrl: levels[index].image_path, index: index,questions: levels,level:levels[index].level,questId: question.id,title: question.gameQus),
                        //                           ),
                        //                         );
                        //
                        //
                        //                       },
                        //                       child: Text(" Start",style: TextStyle(color: Colors.white ),)
                        //                   ),
                        //                 ),
                        //               ],
                        //             )
                        //           ],
                        //         );
                        //       }
                        //   );
                        // }else if(coinCount <=0){
                        //   Fluttertoast.showToast(msg: 'Not enough Coin');
                        // }
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 14,top: 6),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                        child: Center(
                          child: Text(
                            "${question}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins Regular',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context) {
    switch (widget.gameName) {
      case 'Drag and Learn':
        // Navigator.push(context, MaterialPageRoute(builder: (_) => DragAndLearnApp(level: null,)));
        break;
      case 'Picture Grammar Quest':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PictureGrammarQuestScreen()));
        break;
      case 'Action Snap':

        break;
    }
  }
}

class _GrammarConceptCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _GrammarConceptCard({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}