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

  // void _showQuestionsBottomSheet() {
  //   showModalBottomSheet(
  //     backgroundColor: Colors.white,
  //     context: context,
  //     isScrollControlled: true, // Allows the sheet to take more height
  //     builder: (context) {
  //       return Container(
  //         padding: EdgeInsets.all(16),
  //         height: MediaQuery.of(context).size.height * 0.85, // Increased height to 85% of screen
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Center(
  //               child: Container(
  //                 width: 40,
  //                 height: 4,
  //                 margin: EdgeInsets.only(bottom: 16),
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey[300],
  //                   borderRadius: BorderRadius.circular(2),
  //                 ),
  //               ),
  //             ),
  //             Text(
  //               'Frequently Asked Questions',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //                 color: Color(0xFF49329A),
  //             ),
  //             ),
  //             SizedBox(height: 16),
  //             Expanded(
  //               child: ListView.builder(
  //                 itemCount: qaPairs.length,
  //                 itemBuilder: (context, index) {
  //                   final question = qaPairs.keys.elementAt(index);
  //                   return Card(
  //                     color: Colors.white,
  //                     elevation: 0,
  //                     margin: EdgeInsets.symmetric(vertical: 6),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(12)),
  //                     child: ListTile(
  //                       contentPadding: EdgeInsets.symmetric(
  //                         horizontal: 16, vertical: 12),
  //                       title: Text(
  //                         question,
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                       trailing: Icon(Icons.arrow_forward_ios, size: 16),
  //                       onTap: () {
  //                         Navigator.pop(context);
  //                         _addMessage(question, true);
  //                         // Simulate bot response after a short delay
  //                         Future.delayed(Duration(seconds: 1), () {
  //                           _addMessage(qaPairs[question]!, false);
  //                         });
  //                       },
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }
  void _showQuestionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF49329A),
                    ),
                  ),
                  InkWell(
                      onTap: (){
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.cancel_outlined,color: Colors.red,)),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<FAQCubit, FAQState>(
                  builder: (context, state) {
                    if (state is FAQLoading) {
                      return Center(child: CircularProgressIndicator());
                    } else if (state is FAQLoaded) {
                      final faqs = state.faqs;
                      return ListView.builder(
                        itemCount: faqs.length,
                        itemBuilder: (context, index) {
                          final faq = faqs[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              title: Text(
                                faq.question,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.pop(context);
                                _addMessage(faq.question, true);
                                Future.delayed(Duration(seconds: 1), () {
                                  _addMessage(faq.answer, false);
                                });
                              },
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
        );
      },
    );
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF49329A),
        onPressed: _showQuestionsBottomSheet,
        child: Icon(Icons.help_outline, color: Colors.white),
      ),
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
      body: BlocBuilder<UserSupportCubit, UserSupportState>(
  builder: (context, state) {
    if(state is UserSupportLoaded){
      if(oldMsgUpdate==false){
        Future.delayed(Duration.zero,(){
          messages.addAll(state.supports);
          setState(() {
            oldMsgUpdate=true;
          });
        });

      }
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0F7FF),
              Color(0xFFEAE4FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Align(
                    alignment: message['isMe'] == 'true'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ChatMessageLayout(
                      isMeChatting: message['isMe'] == 'true',
                      messageBody: message['message']!,
                      timestamp: message['time']!,
                      senderName: message['isMe'] == 'true' ? null : 'Helper',
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10,bottom: 36, left: 10,right: 90),
              child: BlocConsumer<HelperUserMessageCubit, HelperUserMessageState>(listener: (context,state){
                if(state is HelperUserMessageLoaded){
                  Future.delayed(Duration.zero,(){
                    setState(() {
                      context.read<UserSupportCubit>().fetchUserSupport();
                      oldMsgUpdate=false;
                      _messageController.clear();
                    });
                  });
                }
              },
                builder: (context, sendMessageState) {
                  return TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          child:InkWell(
                              onTap: (){
                                if(_messageController.text.isNotEmpty){
                                  context.read<HelperUserMessageCubit>().sendUserMessage(_messageController.text);
                                }
                              },
                              child: Icon(Icons.send)),
                        ),
                      ),
                    ),

                  );
                },
              ),
            ),
          ],
        ),
      );
    }else if (state is UserSupportLoading){
      return Center(
        child: SizedBox(
          height: 30,
          width: 30,
          child: CircularProgressIndicator(),
        ),
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