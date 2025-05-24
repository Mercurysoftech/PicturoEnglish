import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/cubits/drag_and_learn_cubit/drag_and_learn_cubit.dart';

import '../../models/dragand_learn_model.dart';
import '../dragandlearnpage.dart';

class DragLearnPage extends StatefulWidget {
  const DragLearnPage({super.key,required this.bookId});
  final int bookId;

  @override
  State<DragLearnPage> createState() => _DragLearnPageState();
}

class _DragLearnPageState extends State<DragLearnPage> {

  @override
  void initState() {
    // TODO: implement initState
    context.read<DragLearnCubit>().fetchDragLearnData(bookId:1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Levels", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<DragLearnCubit, DragLearnState>(
        builder: (context, state) {
          print("sldkclskdc ${state.runtimeType}");
          if(state is DragLearnLoaded){
            DragAndLearnLevelModel data=state.data;
            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: data.levels?.length,
              itemBuilder: (context, index) {

                return InkWell(
                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DragAndLearnApp(level:data.levels?[index] ,)),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Level Header
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                            ),
                            borderRadius: BorderRadius.vertical(top: Radius
                                .circular(20)),
                          ),
                          child: Text(
                            "Level ${data.levels?[index].level}",
                            style: TextStyle(color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }else if (state is DragLearnLoading){
            return Center(
              child: CircularProgressIndicator(),
            );
          }else{
            return Center(
              child: Text("Something Went Wrong Please Try Again"),
            );
          }

        },
      ),
    );
  }
}
