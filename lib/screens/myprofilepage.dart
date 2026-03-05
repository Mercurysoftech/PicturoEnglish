import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:picturo_app/classes/helper/logout_cleanup_manager.dart';
import 'package:picturo_app/classes/services/cache_clear_utility.dart';
import 'package:picturo_app/classes/services/connectivity_service.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/cubits/get_sub_topics_list/get_sub_topics_list_cubit.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/providers/remaining_minutes_provider.dart';
import 'package:picturo_app/providers/unread_count_provider.dart';
import 'package:picturo_app/providers/userprovider.dart';
import 'package:picturo_app/responses/my_profile_response.dart';
import 'package:picturo_app/screens/accountdetailsshow.dart';
import 'package:picturo_app/screens/blockeduserspage.dart';
import 'package:picturo_app/screens/changelanguagepage.dart';
import 'package:picturo_app/screens/deleteaccountpage.dart';
import 'package:picturo_app/screens/editprofilepage.dart';
import 'package:picturo_app/screens/helperbotpage.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/screens/loginscreen.dart';
import 'package:picturo_app/screens/premium_plans_screen.dart';
import 'package:picturo_app/screens/premiumscreenpage.dart';
import 'package:picturo_app/screens/transactionhistory.dart';
import 'package:picturo_app/screens/widgets/commons.dart';
import 'package:picturo_app/screens/withdrawpage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../cubits/call_cubit/call_socket_handle_cubit.dart';
import '../cubits/get_coins_cubit/coins_cubit.dart';
import '../cubits/user_status/user_status_cubit.dart';
import '../services/chat_socket_service.dart';
import '../utils/common_app_bar.dart';
import 'earnings_ref/earnings_referral.dart';
import 'locationgetpage.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  String? _avatarUrl;
  ApiService? apiService;
  bool _isLoading = true;
  int? _currentAvatarId;
  final String baseUrl = "https://cdn.jsdelivr.net/gh/Mercurysoftech/PicturoEnglish@main/images_app/";
   late ApiService _apiService;
  
    
  Future<void> initializeApiService() async {
  try {
    apiService = await ApiService.create();
    final userResponse = await apiService!.fetchProfileDetails();
    
    if (mounted) {
      setState(() {
        _currentAvatarId = userResponse.user.avatarId;
      });
      await _loadAvatar(); // Load avatar after setting the ID
    }
  } catch (e) {
    print("Error initializing API service: $e");
    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentAvatarId = 0; // Fallback to default avatar
      });
    }
  }
}
  Future<void> _loadAvatar() async {
  if (apiService == null || _currentAvatarId == null || _currentAvatarId == 0) {
    print('API service not initialized or invalid avatar ID: $_currentAvatarId');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _avatarUrl = null;
      });
    }
    return;
  }
  
  try {
    print('Fetching avatars for ID: $_currentAvatarId');
    final avatarResponse = await apiService!.fetchAvatars();
    
    // Debug: Print all received avatars
    print('Received ${avatarResponse.data.length} avatars:');
    for (var avatar in avatarResponse.data) {
      print('Avatar ID: ${avatar.id}, URL: ${avatar.avatarUrl}');
    }

    // Find matching avatar
    final avatar = avatarResponse.data.firstWhere(
      (a) => a.id == _currentAvatarId,
      orElse: () {
        print('No avatar found with ID $_currentAvatarId');
        throw Exception('Avatar not found');
      },
    );

    final fullUrl = baseUrl + avatar.avatarUrl;
    print('Found avatar. Full URL: $fullUrl');

    if (mounted) {
      setState(() {
        _avatarUrl = fullUrl;
      });
    }
  } catch (e) {
    print('Error loading avatar: $e');
    if (mounted) {
      setState(() {
        _avatarUrl = null;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load avatar')),
    );
  }
}

  @override
  void initState() {
    super.initState();
    initializeApiService();
     // Initialize the provider when the screen loads
    Future.delayed(Duration.zero,(){
      final profileProvider = context.read<ProfileProvider>();

      if(!profileProvider.onceLoaded){
        context.read<ProfileProvider>().initialize();
      }
    });

    // Provider.of<ProfileProvider>(context, listen: false).initialize()
    ApiService.create().then((service) {
      _apiService = service;
    });

    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);

    connectivityService.addListener(() {
      if (connectivityService.isOnline) {
        // Re-fetch profile when internet comes back
        context.read<ProfileProvider>().fetchProfile();
      }
    });
  }
  

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: CommonAppBar(
        title:"My Profile" ,isBackbutton: true,
        actions: [
          CoinBadge(),
          SizedBox(width: 20,)
      ],),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Color(0xFFE0F7FF),
            Color(0xFFEAE4FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,  
          ),
        ),
        child:  profileProvider.isLoading
            ? Center(child: CircularProgressIndicator())
            : profileProvider.user == null
                ? Center(child: Text('No profile data available'))
                : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 16),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                          _buildProfileCard(context, profileProvider),
                          SizedBox(height: 10),
                          _buildUserDetailsCard(profileProvider.user!,profileProvider.wallet!),
                          SizedBox(height: 10),

                          PremiumButton(userName: profileProvider.username??'',),
                          SizedBox(height: 10),
                          _buildSettingsOption(Icons.language, "Language", context,profileProvider),
                              SizedBox(height: 10),
                          _buildSettingsOption(CupertinoIcons.location, "Location", context,profileProvider),
                              // SizedBox(height: 10),
                          // _buildSettingsOption(Icons.location_city, "Update Location", context,profileProvider),
                              SizedBox(height: 10),
                          _buildSettingsOption(CupertinoIcons.money_dollar_circle, "My Wallet", context,profileProvider),
                          SizedBox(height: 10),
                          _buildBankDetailsOption("Bank account details", context),
                           SizedBox(height: 10),
                          _buildWithdrawlOption("Withdraw", context),
                          SizedBox(height: 10),
                          _buildTransactionDetailsOption("Transaction History", context),
                          SizedBox(height: 10),
                          _buildSettingsOption(Icons.block, "Blocked users", context,profileProvider),
                          SizedBox(height: 10),
                          _buildSettingsOption(Icons.help_outline, "Help", context,profileProvider),
                          SizedBox(height: 10),
                          _buildSettingsOption(Icons.share, "Share This App", context,profileProvider),
                          SizedBox(height: 10,),
                          CacheClearButton(),
                          SizedBox(height: 10),
                          _buildSettingsOption(FontAwesome.trash_o, "Delete Account", context,profileProvider),
                          SizedBox(height: 10),
                          _buildLogoutButton(),
                          SizedBox(height: 20,),
                          
                        ],
                      ),
                    ),
                                  ),
                  ),
                ),
      ),
      );
  }

   Widget _buildProfileCard(BuildContext context, ProfileProvider profileProvider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditProfile(
            profileId: profileProvider.user!.avatarId,
            userName: profileProvider.user!.username,
            email: profileProvider.user!.email,
            mobile: profileProvider.user!.mobile,
          )),
        ).then((_) {
          // Refresh profile data when returning from edit screen
          profileProvider.fetchProfile();
        });
      },
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: profileProvider.getAvatarImage(),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileProvider.user!.username,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF464646),
                        fontFamily: 'Poppins Regular',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      profileProvider.user!.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF464646),
                        fontFamily: 'Poppins Regular',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF49329A),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetailsCard(User user,Wallet wallet) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("User name", user.username),
            _buildDetailRow("Referral code", user.referralCode), 
            _buildDetailRow("Numbers of referral",wallet?.transactions?.length.toString() ?? "0"), 
            _buildDetailRow("Total earning", "₹ ${wallet?.totalBalance ?? 0}"),
            //_buildDetailRow("Plan Ends", user?.planEndTime ?? "No Active Plans"), 
            _buildDetailRow("Location", user.location),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    bool isValueEmpty = value.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // First Text (Label)
          Expanded(
            flex: 2, // Equal space
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Color(0XFF49329A), fontFamily: 'Poppins Regular', fontWeight: FontWeight.bold),
              textAlign: TextAlign.start, // Align text to the start
            ),
          ),
          // Colon
          Expanded(
            child: Text(
              ":",
              style: TextStyle(fontSize: 14, color: Color(0xFF49329A), fontFamily: 'Poppins Regular', fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, // Align colon to the center
            ),
          ),
          // Second Text (Value)
          (label=='Location')?Expanded(
            flex:4, // Equal space
            child: Text(
              !isValueEmpty ? value : 'No Location Provided',
              maxLines: 4,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF49329A), fontFamily: 'Poppins Regular',
              ),
              textAlign: TextAlign.start, // Align text to the end
              overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
            ),
          ):Expanded(
            flex:4, // Equal space
            child: Row(
              children: [
                Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF49329A), fontFamily: 'Poppins Regular',
                  ),
                  textAlign: TextAlign.start, // Align text to the end
                  overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
                ),
                (label=="Referral code")?const SizedBox(width: 6,):SizedBox(),
                (label=="Referral code")?InkWell(
                    onTap: (){
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied to clipboard!')),
                      );
                    },
                    child: Icon(Icons.copy,size: 18,)):SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(IconData icon, String title, BuildContext context,ProfileProvider user) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(5.0),
        child: ListTile(
          leading: Icon(icon, color: Color(0XFF49329A)),
          title: Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins Regular')),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          onTap: () {
            if(title=="Share This App"){
              Share.share("https://play.google.com/store/apps/details?id=com.picturo.picturoenglish&pcampaignid=web_share");
            }else
            if (title == 'My Wallet') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WalletReferralPage()), // Navigate to ChangeLanguagePage
              );
            } else if (title == 'Update Location') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LocationGetPage(isFromProfile: true,)), // Navigate to ChangeLanguagePage
              );
            } else if (title == 'Language') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeLanguagePage()), // Navigate to ChangeLanguagePage
              );
            }else if (title == 'Location') {
              Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => LocationGetPage(isFromProfile: true,user: user.user,)),
                                            );
            } else if(title=='Transaction History'){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TransactionHistoryPage()), // Navigate to BlockedUsersPage
              );
            }
            else if(title=='Help'){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelperBotScreen()), // Navigate to BlockedUsersPage
              );
            }
             else if(title=='Delete Account'){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeleteAccountPage()), // Navigate to BlockedUsersPage
              );
            }
             else {

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BlockedUsersScreen(user: user,)), // Navigate to BlockedUsersPage
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildWithdrawlOption(String title, BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(5.0),
        child: ListTile(
          leading: Icon(FontAwesome.money, color: Color(0XFF49329A)),
          title: Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins Regular')),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WithdrawlAmountPage()), // Navigate to AccountDetailShow
            );
          },
        ),
      ),
    );
  }

  Widget _buildBankDetailsOption(String title, BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(5.0),
        child: ListTile(
          leading: SvgPicture.string(
            Svgfiles.bankSvg,
            width: 22,
            height: 22,
            color: Color(0XFF49329A),
          ),
          title: Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins Regular')),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AccountDetailShow()), // Navigate to AccountDetailShow
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransactionDetailsOption(String title, BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(5.0),
        child: ListTile(
          leading: SvgPicture.string(
            Svgfiles.transactionSvg,
            width: 24,
            height: 24,
            color: Color(0XFF49329A),
          ),
          title: Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins Regular')),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TransactionHistoryPage()), // Navigate to AccountDetailShow
            );
          },
        ),
      ),
    );
  }

  Widget _buildWithdrawDetailsOption(String title, BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(5.0),
        child: ListTile(
          leading: SvgPicture.string(
            Svgfiles.transactionSvg,
            width: 24,
            height: 24,
            color: Color(0XFF49329A),
          ),
          title: Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins Regular')),
          trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AccountDetailShow()), // Navigate to AccountDetailShow
            );
          },
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
  // Show confirmation dialog
  bool? confirmLogout = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Logout", style: TextStyle(fontFamily: 'Poppins Regular')),
        content: Text("Are you sure you want to logout?", 
            style: TextStyle(fontFamily: 'Poppins Regular')),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel", 
                style: TextStyle(
                  color: Color(0xFF49329A), 
                  fontFamily: 'Poppins Regular'
                ),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text("Logout", 
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Poppins Regular'
                )),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );

  // Only proceed if user confirms
  if (confirmLogout == true) {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Logging out...',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins Regular',
                  fontSize: 14
                ),
              ),
            ],
          ),
        ),
      );

      print("🚀 Starting logout process...");

      // 1. Call logout API
      try {
        final response = await apiService!.logoutAccount();
        print("✅ 1. Logout API called");
      } catch (e) {
        print("⚠️ 1. Logout API error: $e");
      }

      // 2. Disconnect CallSocket FIRST (before clearing SharedPreferences)
      print("🔌 2. Disconnecting CallSocket...");
      try {
        await context.read<CallSocketHandleCubit>().fullResetForLogout();
        print("✅ 2. CallSocket reset done");
      } catch (e) {
        print("❌ 2. CallSocket reset error: $e");
      }

      // 3. Disconnect ChatSocket (before clearing SharedPreferences)
      print("🔌 3. Disconnecting ChatSocket...");
      try {
        await ChatSocket.fullCleanupForLogout();
        print("✅ 3. ChatSocket cleanup done");
      } catch (e) {
        print("❌ 3. ChatSocket cleanup error: $e");
      }

      // 4. Clear UserStatusCubit
      print("🗑️ 4. Clearing UserStatusCubit...");
      try {
        context.read<UserStatusCubit>().clearAllStatus();
        print("✅ 4. UserStatusCubit cleared");
      } catch (e) {
        print("❌ 4. UserStatusCubit error: $e");
      }

      // 5. Clear ProfileProvider
      print("🗑️ 5. Clearing ProfileProvider...");
      try {
        await context.read<ProfileProvider>().clearProfile();
        print("✅ 5. ProfileProvider cleared");
      } catch (e) {
        print("❌ 5. ProfileProvider error: $e");
      }

      // 6. Clear RemainingMinutesProvider
      print("🗑️ 6. Clearing RemainingMinutesProvider...");
      try {
        Provider.of<RemainingMinutesProvider>(context, listen: false).reset();
        print("✅ 6. RemainingMinutesProvider cleared");
      } catch (e) {
        print("❌ 6. RemainingMinutesProvider error: $e");
      }

      // 7. CLEAR ALL SharedPreferences (this is the main cleanup)
      print("🗑️ 7. Clearing ALL SharedPreferences...");
      try {
        await LogoutCleanupManager.performCompleteCleanup();
        print("✅ 7. SharedPreferences cleared");
      } catch (e) {
        print("❌ 7. SharedPreferences error: $e");
      }

      // 8. Clear questions cache
      print("🗑️ 8. Clearing questions cache...");
      try {
        await LocalStorageHelper.clearAllQuestionsCache();
        print("✅ 8. Questions cache cleared");
      } catch (e) {
        print("❌ 8. Questions cache error: $e");
      }

      print("✅✅✅ LOGOUT COMPLETE ✅✅✅");

      // Close loading indicator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // 8. Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      print("✅ Logout complete!");

    } catch (e) {
      // Close loading indicator if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      print("❌ Logout error: $e");
    }
  }
}
  Widget _buildLogoutButton() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(5.0),
        child: ListTile(
          leading: Icon(Icons.logout, color: Color(0xFFE54547)),
          title: Text("Log out",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins Regular',
                  color: Color(0xFFE54547))),
          onTap: () {
            _logout(context);
          },
        ),
      ),
    );
  }

  Widget _buildClearCacheOption() {
  return Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: EdgeInsets.all(5.0),
      child: ListTile(
        leading: Icon(Icons.cached, color: Color(0XFF49329A)),
        title: Text("Clear Cache",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins Regular')),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        onTap: () => {
           Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CacheClearButton()),
        (route) => false,
      )
        },
      ),
    ),
  );
}

}

class PremiumButton extends StatelessWidget {
  const PremiumButton({super.key, required this.userName});
  final String userName;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PremiumPlansScreen(userName: userName, isChatBot: false, isCall: false)), // Navigate to PremiumScreen
        );
      },
      child: Container(
        width: double.infinity, // Full width
        height: 70, // Button height
        decoration: BoxDecoration(
          color: Colors.grey[800], // Dark background color
          borderRadius: BorderRadius.circular(20), // Smooth rounded edges
        ),
        child: Stack(
          children: [
            // Left Gold Section (No Radius)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: ClipPath(
                clipper: DiagonalClipper(), // Use updated clipper
                child: Container(
                  width: 75, // Width of the gold section
                  decoration: BoxDecoration(
                    color: Color(0xFFE1A732), // Gold color
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20), // Set the top left radius
                      topRight: Radius.circular(20), // Set the top right radius
                      bottomLeft: Radius.circular(20), // Set the bottom left radius
                    ),
                  ),
                ),
              ),
            ),
            // Gold Slash Line after Gold Section
            Positioned.fill(
              child: CustomPaint(
                painter: SlashPainter(),
              ),
            ),
            // Star Icon inside Gold Section
            Positioned(
              left: 25, // Adjust to match design
              top: 75 / 2 - 12, // Centering vertically
              child: Image.asset('assets/star.png', width: 18, height: 18),
            ),
            // Centered Text
            Align(
              alignment: Alignment.center,
              child: Text(
                "Unlock Premium Picture",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins Regular',
                  fontSize: 16,
                ),
              ),
            ),
            // Right Arrow Icon
            Positioned(
              right: 30,
              top: 70 / 2 - 12, // Centering vertically
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}

// Custom Clipper: Diagonal Slash Line
class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    
    path.moveTo(0, 0); // Start at top-left
    path.lineTo(size.width - 20, 0); // Straight top
    path.lineTo(size.width, size.height); // Diagonal cut
    path.lineTo(0, size.height); // Left-side bottom
    path.close(); // Close the path

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom Painter for Slash Line
class SlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = const Color(0xFFE1A732) // Gold color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Adjusted x-position to bring the slash line closer
    double startX = 60; // Closer to the gold section
    double endX = 80;   // Closer diagonal end

    // Draw the diagonal slash line closer to the gold section
    canvas.drawLine(
      Offset(startX, 0),  // Start point after gold section
      Offset(endX, size.height),  // End point diagonal
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinCubit, CoinState>(
      builder: (context, state) {
        if (state is CoinLoading) {
          return SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 0.6,));
        } else if (state is CoinLoaded) {
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WalletReferralPage()),
    );
  },
  child: Badge(
    // label: Text(
    //   "${state.coins}",
    //   style: const TextStyle(
    //     color: Color(0xFF49329A),
    //     fontWeight: FontWeight.w600,
    //   ),
    // ),
     backgroundColor: Colors.transparent,
    child: const ImageIcon(
  AssetImage('assets/wallet.png'), // path to your image asset
  color: Colors.white,
  size: 28,
)
  ),
)

          );
        } else if (state is CoinError) {
          return SizedBox();
        }
        return Container();
      },
    );

  }
}

