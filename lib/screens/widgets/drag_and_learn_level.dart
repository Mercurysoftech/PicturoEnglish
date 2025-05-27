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
    context.read<DragLearnCubit>().fetchDragLearnData(bookId:widget.bookId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 15.0, left: 24.0), // Adjust top padding
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0), // Adjust top padding
            child: Row(
              children: [
                Text(
                  'Levels',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins Regular',
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      body: BlocBuilder<DragLearnCubit, DragLearnState>(
        builder: (context, state) {

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
                            gradient: (data.levels?[index].completed??false)?LinearGradient(
                              colors: [Colors.green, Colors.deepPurpleAccent],
                            ):null,
                            borderRadius: BorderRadius.vertical(top: Radius
                                .circular(20)),
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Level ${data.levels?[index].level}",
                                style: TextStyle(color:  (data.levels?[index].completed??false)?Colors.white:Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              (data.levels?[index].completed??false)?Text(
                                "Completed",
                                style: TextStyle(color:  Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ):SizedBox(),

                            ],
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
