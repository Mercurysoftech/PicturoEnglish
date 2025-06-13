import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picturo_app/screens/widgets/commons.dart';

import '../cubits/get_avatar_cubit/get_avatar_cubit.dart';
import '../screens/myprofilepage.dart';
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
      preferredSize: Size.fromHeight(68),
      child: AppBar(titleSpacing: 18,
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
        actions: (isFromHomePage!=null&&isFromHomePage==true && actions==null)? [
        Padding(
            padding: const EdgeInsets.only(top: 10.0,left: 8, right: 24.0),
            child: Row(
              children: [
                // CoinBadge(),
                // const SizedBox(width:20),
                BlocBuilder<AvatarCubit, AvatarState>(
                  builder: (context, state) {

                    if (state is AvatarLoaded) {
                      return InkWell(
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyProfileScreen()),
                          );
                        },
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Color(0xFF49329A),
                          backgroundImage: state.imageProvider,
                        ),
                      );
                    } else if (state is AvatarLoading) {
                      return const CircularProgressIndicator();
                    } else {
                      // Fallback image
                      final fallback = context.read<AvatarCubit>().getFallbackAvatarImage();
                      return InkWell(
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyProfileScreen()),
                          );
                        },
                        child: CircleAvatar(
                          backgroundImage: fallback,
                          radius: 40,
                        ),
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


  @override
  // TODO: implement child
  Widget get child => SizedBox();

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(72);
}
