import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/screens/requestspage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/utils/common_file.dart';

import '../cubits/bottom_navigator_index_cubit.dart';
import '../cubits/get_avatar_cubit/get_avatar_cubit.dart';
import '../cubits/get_notification/get_notification_cubit.dart';
import '../models/notification_model.dart';
import '../utils/common_app_bar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  @override
  void initState() {
    // TODO: implement initState
    context.read<NotificationCubit>().fetchNotifications();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Color(0xFFE0F7FF),
          appBar: CommonAppBar(title:"Notification" ,isFromHomePage: true,),
        body: Column(
          children: [
            // TabBar placed outside of AppBar
            TabBar(onTap: (index){
              if(index==0){

              }
              context.read<NotificationCubit>().fetchNotifications();
            },
              labelStyle: TextStyle(fontWeight: FontWeight.bold,fontFamily: AppConstants.commonFont,),

              tabs: [
                Tab(
                    text: 'Notifications'),
                Tab(text: 'Requests'),
              ],
            ),
            Expanded(
              child:
        Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE0F7FF),
            Color(0xFFEAE4FF),
          ], // Set your gradient colors here
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child:
        TabBarView(
          children: [
            DailyTaskTab(),
            RequestsPage()
          ],
        ),

      ),
      ),
          ],
        )
      ),
    );
  }

  Future<String> _getCurrentUserAvatar() async {
  try {
    final apiService = await ApiService.create();
    final profile = await apiService.fetchProfileDetails();

    if (profile.avatarId == null || profile.avatarId == 0) {
      throw Exception('Using default avatar');
    }

    final avatarResponse = await apiService.fetchAvatars();
    final avatar = avatarResponse.data.firstWhere(
      (a) => a.id == profile.avatarId,
      orElse: () => throw Exception('Avatar not found'),
    );

    return 'https://picturoenglish.com/admin/${avatar.avatarUrl}';
  } catch (e) {
    print('Error fetching current user avatar: $e');
    throw e; // This will trigger the default avatar fallback
  }
}
}

class DailyTaskTab extends StatelessWidget {
  const DailyTaskTab({super.key});

  @override
  Widget build(BuildContext context) {
    String formatDateTime(String inputDate) {
      DateTime parsed = DateTime.parse(inputDate);
      return DateFormat('dd-MM-yyyy HH:mm').format(parsed);
    }
    return BlocBuilder<NotificationCubit, NotificationState>(
  builder: (context, state) {
    if(state is NotificationLoaded){
      List<NotificationModel> notifications=state.notifications;

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Scrollbar(
          child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: notifications.length,
              itemBuilder: (BuildContext context,index){
            return   Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // SizedBox(width: 8),
                        Text('${notifications[index].title},', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins Regular')),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(notifications[index].body,
                        style: TextStyle(fontSize: 14, fontFamily: 'Poppins Regular')),
                    SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDateTime(notifications[index].createdAt),
                            style: TextStyle(fontSize: 14, fontFamily: 'Poppins Regular')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF49329A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            if((notifications[index].body.toString().toLowerCase().contains("game")||notifications[index].title.toLowerCase().toString().contains("game"))){
                              context.read<BottomNavigatorIndexCubit>().onChageIndex(2);
                            }else{
                              context.read<BottomNavigatorIndexCubit>().onChageIndex(0);
                            }
                          },
                          child: Text((notifications[index].body.toString().toLowerCase().contains("game")||notifications[index].title.toLowerCase().toString().contains("game"))?'Play now':"View", style: TextStyle(fontFamily: 'Poppins Regular', fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      );

    }else{
      return Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(),
        ),
      );
    }
  },
);
  }
}
