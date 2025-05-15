import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  double progress = 0.0; // value between 0 and 1
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProgress();
  }

  Future<void> fetchProgress() async {
    final url = Uri.parse("https://picturoenglish.com/api/getprogress_percentage.php");
    final body = {
      "book_id": widget.bookId,
      "topic_id": widget.topicId,
    };
    SharedPreferences pref =await SharedPreferences.getInstance();
    String? token = pref.getString("auth_token");
    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {

        final data = json.decode(response.body);
        if (data['success'] == true) {
          final int totalQuestions = data['total_questions'];
          final int readQuestions = data['read_questions'];
          if (totalQuestions > 0) {
            progress = readQuestions / totalQuestions;
          } else {
            progress = 0.0;
          }
        }
      }
    } catch (e) {
      print("Error fetching progress: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: isLoading
          ?
      Center(
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
      )
          : Column(
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
                width: MediaQuery.of(context).size.width * progress,
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
              "$percentage%",
              style: const TextStyle(
                color: Color(0xFF49329A),
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins Regular',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
