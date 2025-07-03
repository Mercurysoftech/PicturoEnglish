import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:picturo_app/classes/svgfiles.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/responses/my_profile_response.dart';
import 'package:picturo_app/screens/accountdetailsshow.dart';
import 'package:picturo_app/screens/blockeduserspage.dart';
import 'package:picturo_app/screens/changelanguagepage.dart';
import 'package:picturo_app/screens/deleteaccountpage.dart';
import 'package:picturo_app/screens/editprofilepage.dart';
import 'package:picturo_app/screens/helperbotpage.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/screens/loginscreen.dart';
import 'package:picturo_app/screens/premiumscreenpage.dart';
import 'package:picturo_app/screens/transactionhistory.dart';
import 'package:picturo_app/screens/widgets/commons.dart';
import 'package:picturo_app/screens/withdrawpage.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cubits/call_cubit/call_socket_handle_cubit.dart';
import '../cubits/get_coins_cubit/coins_cubit.dart';
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
  final String baseUrl = "https://picturoenglish.com/admin/";
   late ApiService _apiService;
  
    
  Future<void> initializeApiService() async {
  try {
    apiService = await ApiService.create();
    final userResponse = await apiService!.fetchProfileDetails();
    
    if (mounted) {
      setState(() {
        _currentAvatarId = userResponse.avatarId;
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
      print("sldclskdcmsdc ${!profileProvider.onceLoaded}");
      if(!profileProvider.onceLoaded){
        context.read<ProfileProvider>().initialize();
      }
    });

    // Provider.of<ProfileProvider>(context, listen: false).initialize()
    ApiService.create().then((service) {
      _apiService = service;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: CommonAppBar(title:"My Profile" ,isBackbutton: true,
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
                          _buildUserDetailsCard(profileProvider.user!),
                          SizedBox(height: 10),
                          PremiumButton(),
                          SizedBox(height: 10),
                          _buildSettingsOption(Icons.language, "Language", context,profileProvider),
                              SizedBox(height: 10),
                          _buildSettingsOption(Icons.location_history, "Location", context,profileProvider),
                              // SizedBox(height: 10),
                          // _buildSettingsOption(Icons.location_city, "Update Location", context,profileProvider),
                              SizedBox(height: 10),
                          _buildSettingsOption(Icons.monetization_on_outlined, "Referral Earning", context,profileProvider),
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
                           SizedBox(height: 10),
                          _buildSettingsOption(Icons.delete_outline, "Delete Account", context,profileProvider),
                          SizedBox(height: 10),
                          _buildLogoutButton(),
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

  Widget _buildUserDetailsCard(UserResponse user) {
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
            _buildDetailRow("User code", user.referralCode), // Replace with actual user code if available
            _buildDetailRow("Numbers of referral", "0"), // Replace with actual referral count if available
            _buildDetailRow("Total earning", "₹ 0"), // Replace with actual earning if available
            _buildDetailRow("Location", user.location),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
              value,
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
            child: Text(
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
            if (title == 'Referral Earning') {
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
          leading: Icon(Icons.money, color: Color(0XFF49329A)),
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
                style: TextStyle(color: Color(0xFF49329A), 
                fontFamily: 'Poppins Regular'),
            ),
            onPressed: () => Navigator.of(context).pop(false),
            ),
          TextButton(
            child: Text("Logout", 
                style: TextStyle(color: Colors.red,
                fontFamily: 'Poppins Regular')),
            onPressed: (){
              print("sdkcmscskcsl;dc");
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
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Call logout API
      final response = await apiService!.logoutAccount();

      // Close loading indicator
      Navigator.of(context).pop();

      // Clear local storage
      context.read<CallSocketHandleCubit>().disposeLocalRender();
      context.read<CallSocketHandleCubit>().disposeRemoteRender();
      context.read<CallSocketHandleCubit>().disposeRenderers();
      context.read<CallSocketHandleCubit>().disposeScoket();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');  // Clear token
      await prefs.setBool('isLoggedIn', false);
      await prefs.clear();

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

    } catch (e) {
      // Close loading indicator if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
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

}

class PremiumButton extends StatelessWidget {
  const PremiumButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PremiumScreen()), // Navigate to PremiumScreen
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
            child: Badge(
              label: Text(
                "${state.coins}",
                style: const TextStyle(
                  color: Color(0xFF49329A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.yellow,
                size: 30,
              ),
            ),
          );
        } else if (state is CoinError) {
          return SizedBox();
        }
        return Container();
      },
    );

  }
}

