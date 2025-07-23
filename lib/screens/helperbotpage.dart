import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/cubits/faq_details_cubit/faq_details_cubit.dart';
import 'package:picturo_app/cubits/helper_user_message_cubit/helper_user_message_cubit.dart';
import 'package:picturo_app/screens/chatmessagelayout.dart';

import '../cubits/get_user_helper_messages/get_user_helper_msg_cubit.dart';

class HelperBotScreen extends StatefulWidget {
  const HelperBotScreen({super.key});

  @override
  State<HelperBotScreen> createState() => _HelperBotScreenState();
}

class _HelperBotScreenState extends State<HelperBotScreen> {
   List<Map<String, String>> messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController=TextEditingController();

  final Map<String, String> qaPairs = {
    "How do I reset my password?": 
        "You can reset your password by going to Settings > Account > Reset Password. You'll receive an email with instructions.",
    "What's your return policy?":
        "We offer a 30-day return policy for most items. Please check the product page for specific details.",
    "How can I track my order?":
        "You can track your order in the app under Orders > Track Order, or use the tracking link in your confirmation email.",
    "Do you offer international shipping?":
        "Yes, we ship to most countries. Shipping costs and delivery times vary by destination.",
    "How do I contact customer support?":
        "You can reach our support team 24/7 through this chat or by email at picturoenglish25@gmail.com.",
    "Where is my order confirmation?":
        "Order confirmations are sent to your registered email. Please check your spam folder if you don't see it.",
    "Can I change my delivery address?":
        "You can change your address within 1 hour of placing the order. After that, please contact support immediately.",
    "What payment methods do you accept?":
        "We accept all major credit cards, RazorPay only",
    "How do I apply a discount code?":
        "Enter your code at checkout in the 'Promo Code' field before completing your purchase.",
    "What are your business hours?":
        "Our customer service is available 24/7. Our physical locations are open Monday-Friday, 9AM-5PM."
  };

  void _addMessage(String message, bool isMe) {
    setState(() {
      messages.add({
        'message': message,
        'isMe': isMe.toString(),
        'time': _getCurrentTime(),
      });
    });
    _scrollToBottom();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${now.minute.toString().padLeft(2, '0')} $amPm';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }




  @override
  void initState() {
    super.initState();
    // Add initial greeting messages
    context.read<UserSupportCubit>().fetchUserSupport();
    context.read<FAQCubit>().fetchFAQs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addMessage("Hello! How can I help you today?", false);
    });
  }
   bool oldMsgUpdate=false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/support.png'),
                  radius: 20,
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Helper',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins Regular'
                      ),
                    ),
                  ],
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

    body: Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<FAQCubit, FAQState>(
              builder: (context, state) {
                if (state is FAQLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is FAQLoaded) {
                  final faqs = state.faqs;
                  return  ListView.builder(
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      final faq = faqs[index];
                      return (faqs.length-1==index)?Row(mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 0,vertical: 22),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Ask Something You Want",
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide(color: Colors.blue),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24,),
                          GestureDetector(
                            onTap: () {
                              // Your submit logic here
                              print("Submit tapped");
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.blue, // Button background color
                                borderRadius: BorderRadius.circular(30), // Rounded corners
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                "Submit",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ):Card(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            faq.question,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Text(
                                faq.answer,
                                style: TextStyle(fontSize: 15),
                              ),
                            ),
                            // Align(
                            //   alignment: Alignment.bottomRight,
                            //   child: Padding(
                            //     padding: EdgeInsets.only(right: 16, bottom: 8),
                            //     child: TextButton.icon(
                            //       onPressed: () {
                            //         Navigator.pop(context);
                            //         _addMessage(faq.question, true);
                            //         Future.delayed(Duration(milliseconds: 600), () {
                            //           _addMessage(faq.answer, false);
                            //         });
                            //       },
                            //       icon: Icon(Icons.chat_bubble_outline, size: 18),
                            //       label: Text("Send to chat"),
                            //     ),
                            //   ),
                            // )
                          ],
                        ),
                      );
                    },
                  );
                } else if (state is FAQError) {
                  return Center(child: Text(state.message));
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}