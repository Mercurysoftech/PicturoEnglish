import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/screens/widgets/commons.dart';

import '../cubits/call_cubit/call_duration_handler/call_duration_handle_cubit.dart';
import '../cubits/call_cubit/call_socket_handle_cubit.dart';
import '../cubits/get_avatar_cubit/get_avatar_cubit.dart';
import '../screens/myprofilepage.dart';
import '../screens/voicecallscreen.dart';
import 'common_file.dart';
class CommonAppBar extends StatelessWidget implements PreferredSize {
   CommonAppBar({super.key,required this.title,this.isFromHomePage,this.isBackbutton,this.onBackButtonTap,this.actions});
  final String title;
   bool? isFromHomePage;
   bool? isBackbutton;
   Function()? onBackButtonTap;
   final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(72),
      child: AppBar(
        titleSpacing: 18,
        backgroundColor: Color(0xFF49329A),
        automaticallyImplyLeading: false,
        leading: (isBackbutton!=null&&isBackbutton==true)?Padding(
          padding: const EdgeInsets.only(left: 18,top: 4.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
            onPressed: onBackButtonTap??(){
              Navigator.pop(context);
            },
          ),
        ):null,
        title: Padding(
          padding: EdgeInsets.only(left: isFromHomePage==true?10.0:0),
          child: Text(
            title.toTitleCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: AppConstants.commonFont,
            ),
          ),
        ),
        actions: (actions!=null)?actions:(isFromHomePage!=null&&isFromHomePage==true && actions==null)? [
        Padding(
            padding: const EdgeInsets.only(top: 2.0,left: 8, right: 28.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BlocBuilder<CallSocketHandleCubit, CallSocketHandleState>(
                  builder: (context, state) {
                    return (context.watch<CallSocketHandleCubit>().isLiveCallActive)?Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: InkWell(
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VoiceCallScreen( callerId:context.read<CallSocketHandleCubit>().targetUserId??0,callerName: "${context.read<CallSocketHandleCubit>().callerName}", callerImage:'',isIncoming: false),
                            ),);
                        },
                        child: Container(
                          height: 30,
                          margin: EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.green.withOpacity(0.12),
                          ),
                          child:   Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Center(
                              child: BlocBuilder<CallTimerCubit, CallTimerState>(
                                builder: (context, timerState) {
                                  return Text(
                                    (state is CallOnHold)?"Call on Hold":formatDuration(timerState.duration),
                                    style: TextStyle(fontSize: 16, color: Colors.green),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ):SizedBox();
                  },
                ),
                // CoinBadge(),
                // const SizedBox(width:20),
                BlocBuilder<AvatarCubit, AvatarState>(
                  builder: (context, state) {

                    if (state is AvatarLoaded) {
                      return Column(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left:4.0),
                            child: InkWell(
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MyProfileScreen()),
                                );
                              },
                              child: CircleAvatar(
                                radius: 17,
                                backgroundColor: Color(0xFF49329A),
                                backgroundImage: state.imageProvider,
                              ),
                            ),
                          ),

                          InkWell(
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MyProfileScreen()),
                                );
                              },
                              child: Text(" Profile",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500,fontSize: 13),)),

                        ],
                      );
                    } else if (state is AvatarLoading) {
                      return const CircularProgressIndicator();
                    } else {
                      // Fallback image
                      final fallback = context.read<AvatarCubit>().getFallbackAvatarImage();
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left:4.0),
                            child: InkWell(
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MyProfileScreen()),
                                );
                              },
                              child: CircleAvatar(
                                backgroundImage: fallback,
                                radius: 15,
                              ),
                            ),
                          ),
                          InkWell(
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MyProfileScreen()),
                                );
                              },
                              child: Text("  Profile",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500,fontSize: 16),)),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ]:[
          CoinBadge(),
          SizedBox(width: 25,)
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
    );
  }

   String formatDuration(Duration duration) {
     String twoDigits(int n) => n.toString().padLeft(2, '0');
     final hours = twoDigits(duration.inHours);
     final minutes = twoDigits(duration.inMinutes.remainder(60));
     final seconds = twoDigits(duration.inSeconds.remainder(60));
     return "$hours:$minutes:$seconds";
   }


  @override
  // TODO: implement child
  Widget get child => SizedBox();

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(72);
}
