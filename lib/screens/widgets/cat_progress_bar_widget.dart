import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:picturo_app/cubits/content_view_per_get/content_view_percentage_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class ProgressBarWidget extends StatefulWidget {
  final int bookId;
  final int topicId;

  const ProgressBarWidget({
    super.key,
    required this.bookId,
    required this.topicId,
  });

  @override
  State<ProgressBarWidget> createState() => _ProgressBarWidgetState();
}

class _ProgressBarWidgetState extends State<ProgressBarWidget> {



  @override
  Widget build(BuildContext context) {


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: BlocBuilder<ProgressCubit, ProgressState>(
        builder: (context, state) {
          if(state is ProgressLoading){
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            );
          }else if(state is ProgressLoaded){
            final percentage = (state.progress * 100).toInt();
            return Column(
              children: [
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      height: 10,
                      width: MediaQuery
                          .of(context)
                          .size
                          .width * state.progress,
                      decoration: BoxDecoration(
                        color: const Color(0xFF49329A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${percentage>100?"100":percentage}%",
                    style: const TextStyle(
                      color: Color(0xFF49329A),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins Regular',
                    ),
                  ),
                ),
              ],
            );
          }else{
            return SizedBox();
          }

        },
      ),
    );
  }
}
