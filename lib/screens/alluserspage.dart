import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/screens/chatscreenpage.dart';

class AllUsersPage extends StatefulWidget {
  const AllUsersPage({super.key});

  @override
  _AllUsersPageState createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {
  final List<Map<String, dynamic>> allUsers = [
    {'name': 'User C', 'initial': 'C', 'image': 'assets/panda.png'},
    {'name': 'User D', 'initial': 'D', 'image': 'assets/avatar_1.png'},
    {'name': 'User E', 'initial': 'E', 'image': 'assets/avatar_2.png'},
    {'name': 'User F', 'initial': 'F', 'image': 'assets/avatar_3.png'},
    {'name': 'User G', 'initial': 'G', 'image': 'assets/avatar_4.png'},
    {'name': 'User H', 'initial': 'H', 'image': 'assets/avatar_8.png'},
    {'name': 'User I', 'initial': 'I', 'image': 'assets/avatar_7.png'},
    {'name': 'User J', 'initial': 'J', 'image': 'assets/avatar_5.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
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
       ListView(
        padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
        children: [
          SizedBox(height: 20,),
          ...allUsers.map((user) => _buildUserTile(context, user)),
        ],
      ),
      ),
    );
  }


  Widget _buildUserTile(BuildContext context, Map<String, dynamic> user) {
    return GestureDetector(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(width: 1, color: Color(0xFFDDDDDD))),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(user['image']),
              radius: 25,
            ),
            SizedBox(width: 10),
            Expanded(
              child: 
                  Text(
                    user['name'],
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins Regular'),
                  ),
            ),GestureDetector(
              onTap: () {
      },
      child:
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFEDE8FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: SvgPicture.string(
          Svgfiles.adduserSvg,
          width: 26,
          height: 26,
          color: Color(0XFF49329A),
        ), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}