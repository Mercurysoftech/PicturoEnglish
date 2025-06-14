import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/responses/books_response.dart';
import 'package:picturo_app/screens/chatbotpage.dart';
import 'package:picturo_app/screens/chatlistpage.dart';
import 'package:picturo_app/screens/gamespage.dart';
import 'package:picturo_app/screens/notificationspage.dart';
import 'package:picturo_app/screens/topicspage.dart';
import 'package:picturo_app/screens/voicecallscreen.dart';
import 'package:picturo_app/screens/widgets/commons.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../cubits/call_cubit/call_duration_handler/call_duration_handle_cubit.dart';
import '../cubits/call_cubit/call_socket_handle_cubit.dart';
import '../cubits/get_avatar_cubit/get_avatar_cubit.dart';
import '../cubits/get_coins_cubit/coins_cubit.dart';
import '../main.dart';
import '../utils/common_app_bar.dart';
import '../utils/common_file.dart';

class Homepage extends StatefulWidget{
  final int? initialIndex;
  const Homepage({super.key, this.initialIndex});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  DateTime? lastPressed;
  ApiService? apiService;
  bool _isLoading = true;

  Future<void> updateFcmToken() async {
    const String url = 'https://picturoenglish.com/api/update_fcm_token.php';
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString("auth_token");
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': token,
        }),
      );
       print("dsljcnsdklcskldcj ${response.body}");
      if (response.statusCode == 200) {
        print('✅ FCM token updated successfully: ${response.body}');
      } else {
        print('❌ Failed to update FCM token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔥 Error updating FCM token: $e');
    }
  }

  final List<String> _navIcons = [
    'assets/house_unfilled.png',
    'assets/chat_unfilled.png',
    'assets/game_unfilled.png',
    'assets/notification_unfilled.png',
  ];

  final List<String> _navIconsSelected = [
    'assets/house_filled.png',
    'assets/chat_filled.png',
    'assets/game_filled.png',
    'assets/notification_filled.png',
  ];

  final List<String> _navLabels = [
    'Home',
    'Chat',
    'Games',
    'Notifications',
  ];

  List<Map<String, dynamic>> _gridItems = [
    {
      'image': 'assets/verbs.png',
      'text': 'Verbs',
      'gradient': LinearGradient(
        colors: [Colors.cyan, Colors.indigo],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'page': TopicsScreen(title: 'Verbs',topicId: 1,),
    },
    {
      'image': 'assets/adverb.png',
      'text': 'Adverbs',
      'gradient': LinearGradient(
        colors: [Color(0xFFDA90FF), Color(0xFF861FBA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'page': TopicsScreen(title: 'Adverb',topicId: 2,),
    },
    {
      'image': 'assets/adjective.png',
      'text': 'Adjectives',
      'gradient': LinearGradient(
        colors: [Color(0xFFFF999B), Color(0xFFA62426)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'page': TopicsScreen(title: 'Adjective',topicId: 3,),
    },
    {
      'image': 'assets/phrasal verb.png',
      'text': 'Phrasal Verbs',
      'gradient': LinearGradient(
        colors: [Color(0xFFFFE09D), Color(0xFFE9A004)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'page': TopicsScreen(title: 'Phrasal Verbs',topicId: 4,),
    },
    {
      'image': 'assets/idioms.png',
      'text': 'Idioms',
      'gradient': LinearGradient(
        colors: [Color(0xFFFF96FF), Color(0xFFAD07AD)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'page': TopicsScreen(title: 'Idioms',topicId: 5,),
    },
    {
      'image': 'assets/adverb.png',
      'text': 'The essential language process',
      'gradient': LinearGradient(
        colors: [Color(0xFF8B8BC4), Color(0xFF8B8BC4)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    },
  ];
  String? currentUserId='';

  // Define the different pages/screens for each bottom navigation item
  final List<Widget> _pages = [];
  Future<void> getCurrentUserAvatar() async {
      context.read<AvatarCubit>().loadAvatar();
  }
  @override
  void initState() {
    getCurrentUserAvatar();
    updateFcmToken();
    super.initState();
     _selectedIndex = widget.initialIndex ?? 0;
    // Initialize the pages with the required data
    _pages.add(HomeContent(gridItems: _gridItems)); // Pass _gridItems to HomeContent
    _pages.add(ChatListPage());
    _pages.add(GamesPage());
    _pages.add(NotificationScreen());

    initializeServices();

    callSocketInit();
    handleCall();
    context.read<CallSocketHandleCubit>().fetchAllUsers();
    // Fetch books data from the API
    fetchBooksAndUpdateGrid();
  }
  void handleCall(){
    FlutterCallkitIncoming.onEvent.listen((event) {


      if(event?.event==Event.actionCallAccept){

        Map<String,dynamic> data=event?.body??{};

        if(currentUserId!=''){
          int userCurrentId=int.parse(currentUserId??"0");
          int target=int.parse(data["extra"]['userId']??"0");
          context.read<CallSocketHandleCubit>().acceptCall(target, userCurrentId);
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VoiceCallScreen( callerId:target,callerName: "${data['nameCaller']}", callerImage:'',isIncoming: false),
              ),);
        }

      }else if(event?.event==Event.actionCallDecline){

        Map<String,dynamic> data=event?.body??{};
        int target=int.parse(data["extra"]['userId']??"0");
        context.read<CallSocketHandleCubit>().endCall(targetUserId: target);

      }else if(event?.event==Event.actionCallEnded){

      }

    });
  }
  void callSocketInit()async{
    final prefs = await SharedPreferences.getInstance();
    String? userId= prefs.getString("user_id");
    currentUserId=userId;
    int? profileProvider=userId!=null&&userId!=''?int.parse(userId):null;
    if(profileProvider!=null){
      context.read<CallSocketHandleCubit>().initCallSocket(currentUserId:profileProvider);
    }
  }

   Future<void> initializeServices() async {
    try {
      // Initialize API service
      apiService = await ApiService.create();

      // Fetch profile details
      final userResponse = await apiService!.fetchProfileDetails();

      // Update ProfileProvider with the fetched data
      if (mounted) {
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        await profileProvider.updateProfile(userResponse);
        final userDetails=profileProvider.fetchProfile();
print('Languages da: ${userResponse.speakingLanguage}');
        // This will update the provider state

        // Alternatively, you could directly set the user if needed:
        // profileProvider._user = userResponse;
        // profileProvider.notifyListeners();
      }
    } catch (e) {
      print("Error initializing services: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  // Function to fetch books and update _gridItems
  Future<void> fetchBooksAndUpdateGrid() async {
    try {
      // Fetch the books data
      final apiService = await ApiService.create();
      BookResponse bookResponse = await apiService.fetchBooks();

      // Extract the book names from the response
      List<String> bookNames = bookResponse.data.map((book) => book.booksName).toList();

      // Update _gridItems with the fetched book names
      setState(() {
        // Keep the last item (LSRW Concept) intact
        _gridItems = _gridItems.take(_gridItems.length - 1).toList();

        // Add the fetched book names to _gridItems
        for (int i = 0; i < bookNames.length; i++) {
          if (i < _gridItems.length) {
            _gridItems[i]['text'] = bookNames[i];
          } else {
            // Add new items if the fetched data is longer than the existing _gridItems
            _gridItems.add({
              'image': 'assets/default_image.png', // Add a default image
              'text': bookNames[i],
              'gradient': LinearGradient(
                colors: [Colors.cyan, Colors.indigo],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            });
          }
        }

        // Add the last item (LSRW Concept) back to the list
        _gridItems.add({
          'image': '',
          'text': 'The essential language process',
          'gradient': Color(0xff8b8b8b80),
        });
      });
    } catch (e) {
      print("Error fetching books: $e");
    }
  }

  Future<bool> onWillPop() async {
    DateTime now = DateTime.now();
    if (lastPressed == null || now.difference(lastPressed!) > Duration(seconds: 2)) {
      lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Press back again to exit')),
      );
      return false;
    }
    return true;
  }



  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
Widget build(BuildContext context) {


  // ignore: deprecated_member_use
  return  WillPopScope(
      onWillPop: onWillPop,
      child:  Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
              top: 71,
              right: 82,
              child: BlocBuilder<CallSocketHandleCubit, CallSocketHandleState>(
  builder: (context, state) {
    return (context.watch<CallSocketHandleCubit>().isLiveCallActive)?InkWell(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceCallScreen( callerId:context.watch<CallSocketHandleCubit>().targetUserId??0,callerName: "${context.watch<CallSocketHandleCubit>().callerName}", callerImage:'',isIncoming: false),
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
              builder: (context, state) {
                return Text(
                  formatDuration(state.duration),
                  style: TextStyle(fontSize: 16, color: Colors.green),
                );
              },
            ),
          ),
        ),
            ),
    ):SizedBox();
  },
))
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,

        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: List.generate(4, (index) {
          return BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == index
                  ? _navIconsSelected[index]
                  : _navIcons[index],
              width: 23,
              height: 28,
              color:_selectedIndex==index? Color(0xFF49329A).withValues(alpha: .8):Colors.grey.shade500,
            ),
            label: _navLabels[index],
          );
        }),
        selectedItemColor: Color(0xFF49329A),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w800
        ),
        unselectedFontSize: 13,
        unselectedLabelStyle: TextStyle(
              color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w700

        ),
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButton: _selectedIndex == 0
          ? ClipOval(
        child: Material(
          color: Color(0xFF49329A), // Transparent background
          child: InkWell(
            onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatBotScreen()),
                );
            },
            child: Container(
              width: 45, // Maintain the size of the button
              height: 45, // Keep the FAB size
              alignment: Alignment.center, // Center the image within the button
              child: Image.asset(
                'assets/fluent_bot-28-filled.png', // Replace with the image you want to use
                width: 28, // Image size, smaller than the button
                height: 28, // Image size, smaller than the button
              ),
            ),
          ),
        ),
      ):null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
  ),
  );
}

}

// Define the different content widgets for each page
class HomeContent extends StatefulWidget {
  final List<Map<String, dynamic>> gridItems;


  const HomeContent({super.key, required this.gridItems});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {


@override
  void initState() {
    super.initState();

    context.read<CoinCubit>().setCoin(1000);
  }

  setCoin()async{

  }
  @override
  Widget build(BuildContext context) {
     DateTime? lastPressed;

    Future<bool> onWillPop() async {
    DateTime now = DateTime.now();
    if (lastPressed == null || now.difference(lastPressed!) > Duration(seconds: 2)) {
      lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Press back again to exit')),
      );
      return false;
    }
    return true;
  }

    return WillPopScope(
      onWillPop: onWillPop,
      child:
    Scaffold(
      backgroundColor: Color(0xFFE0F7FF),
      appBar: CommonAppBar(title:"Home" ,isFromHomePage: true,),
      body: FutureBuilder(
        future: Future.value(widget.gridItems), // Use the gridItems passed to the widget
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading data"));
          } else {
            List<Map<String, dynamic>> items = snapshot.data as List<Map<String, dynamic>>;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE0F7FF),
                    Color(0xFFEAE4FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, top: 18),
                      child: Text(
                        "Topics",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppConstants.commonFont,
                          color: Color(0xFF414141),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.only(left: 24, right: 24, top: 5),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        var gridItem = items[index];
                        return GestureDetector(
                          onTap: () {
                            if (gridItem['text'] == 'The essential language process') {
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => gridItem['page']),
                            );
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient:gridItem['gradient'],
                                  // color: gridItem['text'] == 'The essential language process'
                                  //     ? Colors.grey.withValues(alpha: 0.34)
                                  //     : null,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      spreadRadius: 1,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 18, top: 8, bottom: 8),
                                      child: Container(
                                        height: 55,
                                        width: 55,
                                        alignment: Alignment.bottomCenter,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(gridItem['image']),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        capitalizeFirstLetter(gridItem['text']),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontFamily: AppConstants.commonFont,
                                          fontWeight:(gridItem['text'] == 'The essential language process')?FontWeight.w500: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (gridItem['text'] == 'The essential language process')
                                Positioned(
                                  child: Icon(
                                    Icons.lock,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    ),
    );
  }
}