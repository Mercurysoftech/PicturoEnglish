import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:picturo_app/screens/widgets/commons.dart';

import '../cubits/call_cubit/call_duration_handler/call_duration_handle_cubit.dart';
import '../cubits/call_cubit/call_socket_handle_cubit.dart';
import '../cubits/get_avatar_cubit/get_avatar_cubit.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import '../screens/myprofilepage.dart';
import '../screens/voicecallscreen.dart';
import 'common_file.dart';

class CommonAppBar extends StatelessWidget implements PreferredSize {
  CommonAppBar({
    super.key,
    required this.title,
    this.isFromHomePage,
    this.isBackbutton,
    this.onBackButtonTap,
    this.actions,
  });
  
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
        leading: (isBackbutton != null && isBackbutton == true)
            ? Padding(
                padding: const EdgeInsets.only(left: 18, top: 4.0),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
                  onPressed: onBackButtonTap ??
                      () {
                        Navigator.pop(context);
                      },
                ),
              )
            : null,
        title: Padding(
          padding: EdgeInsets.only(left: isFromHomePage == true ? 10.0 : 0),
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
        actions: (actions != null)
            ? actions
            : (isFromHomePage != null && isFromHomePage == true && actions == null)
                ? [
                    CoinBadge(),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, left: 8, right: 28.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          BlocBuilder<CallSocketHandleCubit, CallSocketHandleState>(
                            builder: (context, state) {
                              return (context.watch<CallSocketHandleCubit>().isLiveCallActive)
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => VoiceCallScreen(
                                                callerId: context.read<CallSocketHandleCubit>().targetUserId ?? 0,
                                                callerName: "${context.read<CallSocketHandleCubit>().callerName}",
                                                callerImage: '',
                                                isIncoming: false,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: 30,
                                          margin: EdgeInsets.only(right: 2),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(30),
                                            color: Colors.green.withOpacity(0.12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Center(
                                              child: BlocBuilder<CallTimerCubit, CallTimerState>(
                                                builder: (context, timerState) {
                                                  return Text(
                                                    (state is CallOnHold)
                                                        ? "Call on Hold"
                                                        : formatDuration(timerState.duration),
                                                    style: TextStyle(fontSize: 16, color: Colors.green),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : SizedBox();
                            },
                          ),
                          // OPTIMIZED AVATAR DISPLAY
                          _buildProfileAvatar(context),
                        ],
                      ),
                    ),
                  ]
                : [
                    CoinBadge(),
                    SizedBox(width: 25),
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

  /// Optimized Profile Avatar - Force fresh load
  Widget _buildProfileAvatar(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        // Always use provider data - it's authoritative
        ImageProvider imageProvider;
        
        if (profileProvider.avatarUrl != null && 
            profileProvider.avatarUrl!.isNotEmpty) {
          // Use network image from provider
          imageProvider = NetworkImage(
            profileProvider.avatarUrl!,
            // Force reload by adding timestamp as cache buster
            headers: {'Cache-Control': 'no-cache'},
          );
          print("🖼️ AppBar using avatar from provider: ${profileProvider.avatarUrl}");
        } else {
          // Use default avatar
          imageProvider = AssetImage('assets/avatar2.png');
          print("🖼️ AppBar using default avatar");
        }

        return _buildAvatarColumn(
          context,
          imageProvider: imageProvider,
          showLoading: profileProvider.isLoading,
        );
      },
    );
  }

  Widget _buildAvatarColumn(
    BuildContext context, {
    required ImageProvider imageProvider,
    bool showLoading = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyProfileScreen()),
              ).then((_) {
                // Refresh avatar when returning from profile
                final provider = Provider.of<ProfileProvider>(
                  context, 
                  listen: false
                );
                if (!provider.isLoading) {
                  provider.fetchProfile();
                }
              });
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFF49329A),
                  backgroundImage: imageProvider,
                  // Force image to reload
                  key: ValueKey(imageProvider.toString()),
                ),
                if (showLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black26,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyProfileScreen()),
            ).then((_) {
              // Refresh avatar when returning from profile
              final provider = Provider.of<ProfileProvider>(
                context, 
                listen: false
              );
              if (!provider.isLoading) {
                provider.fetchProfile();
              }
            });
          },
          child: Text(
            " Profile",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: AppConstants.commonFont,
              fontSize: 13,
            ),
          ),
        ),
      ],
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
  Widget get child => SizedBox();

  @override
  Size get preferredSize => Size.fromHeight(72);
}