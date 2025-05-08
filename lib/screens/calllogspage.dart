import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/screens/chatscreenpage.dart';

class CallLogsPage extends StatefulWidget {
  const CallLogsPage({super.key});

  @override
  _CallLogsPageState createState() => _CallLogsPageState();
}

class _CallLogsPageState extends State<CallLogsPage> {
  final List<Map<String, dynamic>> allUsers = [
    {'name': 'User C', 'initial': 'C', 'image': 'assets/panda.png','callType': 'outgoing',
      'callDate': 'Mar 9, 12:00 PM',},
    {'name': 'User D', 'initial': 'D', 'image': 'assets/avatar_1.png','callType': 'incoming',
      'callDate': 'Mar 8, 10:30 AM',},
    {'name': 'User E', 'initial': 'E', 'image': 'assets/avatar_2.png','callType': 'outgoing',
      'callDate': 'Mar 7, 03:45 PM',},
    {'name': 'User F', 'initial': 'F', 'image': 'assets/avatar_3.png','callType': 'incoming',
      'callDate': 'Mar 6, 09:15 AM',},
    {'name': 'User G', 'initial': 'G', 'image': 'assets/avatar_4.png','callType': 'outgoing',
      'callDate': 'Mar 5, 09:45 AM',},
    {'name': 'User H', 'initial': 'H', 'image': 'assets/avatar_8.png','callType': 'incoming',
      'callDate': 'Mar 4, 04:15 AM',},
    {'name': 'User I', 'initial': 'I', 'image': 'assets/avatar_7.png','callType': 'incoming',
      'callDate': 'Mar 3, 02:15 AM',},
    {'name': 'User J', 'initial': 'J', 'image': 'assets/avatar_5.png','callType': 'outgoing',
      'callDate': 'Mar 2, 04:37 PM',},
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
      child: Center(
        child:  Text('No Call Logs',style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontFamily: 'Poppins Regular',
                ),),
      )
      //  ListView(
      //   padding: EdgeInsets.fromLTRB(15, 0, 15, 15),
      //   children: [
      //     SizedBox(height: 20,),
      //     _buildUserTile(context),
      //   ],
      // ),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context) {  //add Map<String, dynamic> user paramter if you used to show user details for call logs
  // Determine the icon based on the call type
  // final String callIconSvg = user['callType'] == 'outgoing'
  //     ? Svgfiles.outgoingcallSvg
  //     : Svgfiles.incomingcallSvg;

  return GestureDetector(
    child: Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(15),  
      //decoration: BoxDecoration(
      //    color: Colors.white,
      //    borderRadius: BorderRadius.circular(15),
      //    border: Border.all(width: 1, color: Color(0xFFDDDDDD))),
      // child: Row(
      //   children: [
      //     CircleAvatar(
      //       backgroundImage: AssetImage(user['image']),
      //       radius: 25,
      //     ),
      //     SizedBox(width: 10),
      //     Expanded(
      //       child: Column(
      //         crossAxisAlignment: CrossAxisAlignment.start,
      //         children: [
      //           Text(
      //             user['name'],
      //             style: TextStyle(
      //                 fontSize: 14,
      //                 fontWeight: FontWeight.bold,
      //                 fontFamily: 'Poppins Regular'),
      //           ),
      //           Row(
      //             children: [
      //               SvgPicture.string(
      //                 callIconSvg, // Use the appropriate icon
      //                 width: 12,
      //                 height: 12,
      //               ),
      //               SizedBox(
      //                 width: 10,
      //               ),
      //               Text(
      //                 user['callDate'], // Use the call date from the user data
      //                 style: TextStyle(
      //                     color: Colors.grey,
      //                     fontFamily: 'Poppins Regular',
      //                     fontSize: 12),
      //               ),
      //             ],
      //           )
      //         ],
      //       ),
      //     ),
      //     GestureDetector(
      //       onTap: () {
      //         // Navigate to the chat screen when the user tile is clicked
    
      //       },
      //       child: Container(
      //         padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      //         decoration: BoxDecoration(
      //           color: Color(0xFFEDE8FF),
      //           borderRadius: BorderRadius.circular(10),
      //         ),
      //         child: SvgPicture.string(
      //           Svgfiles.svgString,
      //           width: 24,
      //           height: 24,
      //           color: Color(0XFF49329A),
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
    ),
  );
}
}
