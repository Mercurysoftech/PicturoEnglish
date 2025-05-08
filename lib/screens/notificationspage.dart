import 'package:flutter/material.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/screens/requestspage.dart';
import 'package:picturo_app/services/api_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Color(0xFFE0F7FF),
        appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // Increased app bar height
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF49329A),
          title: Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins Regular',),),
           actions: [
  Padding(
    padding: const EdgeInsets.only(top: 10.0, right: 24.0),
    child: FutureBuilder(
      future: _getCurrentUserAvatar(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        }
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyProfileScreen()),
            );
          },
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            backgroundImage: snapshot.hasData
                ? NetworkImage(snapshot.data.toString())
                : AssetImage('assets/avatar2.png') as ImageProvider,
          ),
        );
      },
    ),
  ),
],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
        body: Column(
          children: [
            // TabBar placed outside of AppBar
            TabBar(
              labelStyle: TextStyle(fontWeight: FontWeight.bold,fontFamily: 'Poppins Regular',),
              tabs: [
                Tab(text: 'Notifications'),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // This allows the column to take only the height of its children
        children: [
          Card(
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
                      Image.asset('assets/Emoji.png', width: 24),
                      SizedBox(width: 8),
                      Text('Hello,', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins Regular')),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Did you finish your daily task? Your daily game task is waiting!',
                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins Regular')),
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF49329A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {},
                      child: Text('Play now', style: TextStyle(fontFamily: 'Poppins Regular', fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
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
                      Image.asset('assets/Emoji.png', width: 24),
                      SizedBox(width: 8),
                      Text('Hello Friend !,', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins Regular')),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Did you finish your Weekly task? Your weekly game task is waiting! Come on!',
                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins Regular')),
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF49329A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {},
                      child: Text('Play now', style: TextStyle(fontFamily: 'Poppins Regular', fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
