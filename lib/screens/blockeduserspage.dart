import 'package:flutter/material.dart';


class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlockedUsersScreen(),
    );
  }
}

class BlockedUsersScreen extends StatelessWidget {
  final List<String> blockedUsers = [
    "User A",
    "User B",
    "User C",
    "User D",
    "User E",
  ];

  BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // Increased app bar height
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
                  'Blocked users',
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
      body:Container(
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
       Column(
        children: [
          Padding(
              padding: EdgeInsets.fromLTRB(24, 15, 24, 15),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Color(0xFF49329A), // Set the border color
                    width: 1, // Set the border width
                  ),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Color(0xFF49329A)),
                    hintText: 'Search',
                    hintStyle: TextStyle(fontFamily: 'Poppins Regular'),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Padding(padding: EdgeInsets.only(left: 24,right: 24),
            child: 
            ListView.separated(
              separatorBuilder: (context, index) => SizedBox(height: 10),
              itemCount: blockedUsers.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation:0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage('assets/avatar_1.png'),
                      radius: 25,
                    ),
                    title: Text(blockedUsers[index],style: TextStyle(fontFamily: 'Poppins Regular'),),
                    subtitle: Text('Blocked',style: TextStyle(fontFamily: 'Poppins Regular'),),
                    trailing: TextButton(
                      onPressed: () {
                        // Unblock logic here
                      },
                    
                      child: Text('Unblock',style: TextStyle(fontFamily: 'Poppins Regular',color: Color(0xFF464646)),),
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
}