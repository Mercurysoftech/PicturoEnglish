import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/cubits/faq_details_cubit/faq_details_cubit.dart';
import 'package:picturo_app/cubits/helper_user_message_cubit/helper_user_message_cubit.dart';
import 'package:picturo_app/cubits/get_user_helper_messages/get_user_helper_msg_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class HelperBotScreen extends StatefulWidget {
  const HelperBotScreen({super.key});

  @override
  State<HelperBotScreen> createState() => _HelperBotScreenState();
}

class _HelperBotScreenState extends State<HelperBotScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<UserSupportCubit>().fetchUserSupport();
    context.read<FAQCubit>().fetchFAQs();
  }

  /// 📧 Launch email app
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'picturoenglish25@gmail.com',
      query: Uri.encodeFull('subject=Support Request from Picturo App'),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Gmail.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color(0xFF49329A),
          leading: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/support.png'),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Helper',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins Regular',
                  ),
                ),
              ],
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<FAQCubit, FAQState>(
                builder: (context, state) {
                  if (state is FAQLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is FAQLoaded) {
                    final faqs = state.faqs;
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: faqs.length,
                      itemBuilder: (context, index) {
                        final faq = faqs[index];
                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            backgroundColor: Colors.white,
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              faq.question,
                              style: const TextStyle(
                                fontSize: 15,
                                fontFamily: 'Poppins Regular',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Text(
                                  faq.answer,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Poppins Regular',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else if (state is FAQError) {
                    return Center(child: Text(state.message));
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),

            // 📩 Footer contact text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      "If you have any further questions, contact us at ",
                      style: TextStyle(
                        fontFamily: 'Poppins Regular',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: _launchEmail,
                      child: Text(
                        "picturoenglish25@gmail.com",
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontFamily: 'Poppins Medium',
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(
                      ".",
                      style: TextStyle(
                        fontFamily: 'Poppins Regular',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
