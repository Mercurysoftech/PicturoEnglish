import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:picturo_app/classes/services/connectivity_service.dart';
import 'package:picturo_app/cubits/bottom_navigator_index_cubit.dart';
import 'package:picturo_app/cubits/premium_cubit/premium_plans_cubit.dart';
import 'package:picturo_app/providers/audiosettingsprovider.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/providers/remaining_minutes_provider.dart';
import 'package:picturo_app/providers/requests_provider.dart';
import 'package:picturo_app/providers/unread_count_provider.dart';
import 'package:picturo_app/responses/books_response.dart';
import 'package:picturo_app/screens/call/widgets/call_receive_widget.dart';
import 'package:picturo_app/screens/chatbotpage.dart';
import 'package:picturo_app/screens/chatlistpage.dart';
import 'package:picturo_app/screens/earnings_ref/referral_details.dart';
import 'package:picturo_app/screens/gamespage.dart';
import 'package:picturo_app/screens/notificationspage.dart';
import 'package:picturo_app/screens/topicspage.dart';
import 'package:picturo_app/screens/voicecallscreen.dart';
import 'package:picturo_app/screens/widgets/commons.dart';
import 'package:picturo_app/screens/widgets/offline_indicator.dart';
import 'package:picturo_app/screens/widgets/offline_overlay.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../cubits/call_cubit/call_duration_handler/call_duration_handle_cubit.dart';
import '../cubits/call_cubit/call_socket_handle_cubit.dart';
import '../cubits/get_avatar_cubit/get_avatar_cubit.dart';
import '../cubits/get_coins_cubit/coins_cubit.dart';
import '../cubits/get_notification/get_notification_cubit.dart';
import '../cubits/user_friends_cubit/user_friends_cubit.dart';
import '../cubits/user_status/user_status_cubit.dart';
import '../main.dart';
import '../services/chat_socket_service.dart';
import '../utils/common_app_bar.dart';
import '../utils/common_file.dart';

class Homepage extends StatefulWidget {
  final int initialIndex;
  const Homepage({super.key, this.initialIndex = 0});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  late int _currentIndex;
  DateTime? lastPressed;
  ApiService? apiService;
  bool _isLoading = true;
  bool _booksLoaded = false;

  Future<void> updateFcmToken() async {
  const String url = 'https://picturoenglish.com/api/update_fcm_token.php';
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  try {
    String? token = await messaging.getToken();

    if (token == null) {
      await Future.delayed(Duration(seconds: 2));
      token = await messaging.getToken();
      if (token == null) return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString("auth_token");
    if (authToken == null) return;

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fcm_token': token}),
    );

    if (response.statusCode == 200) {
      print('✅ FCM token updated');
    }
  } catch (e) {
    print('🔥 FCM error: $e');
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

  List<Map<String, dynamic>> _gridItems = [];
  bool _isBooksLoading = true;

  String? currentUserId = '';

  // Define the different pages/screens for each bottom navigation item
  final List<Widget> _pages = [];
  Future<void> getCurrentUserAvatar() async {
    context.read<AvatarCubit>().loadAvatar();
  }

  @override
  void initState() {
    getCurrentUserAvatar();
    updateFcmToken();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _currentIndex = widget.initialIndex;
    final callSocketCubit = context.read<CallSocketHandleCubit>();

    // Initialize ProfileProvider
    _initializeProfileProvider();
    // ✅ iOS VoIP token sync (CRITICAL for incoming call)
WidgetsBinding.instance.addPostFrameCallback((_) async {
  final apiService = await ApiService.create();
  await apiService.syncVoipTokenIfNeeded();
});


    _pages.add(HomeContent(gridItems: _gridItems));
    _pages.add(ChatListPage());
    _pages.add(GamesPage());
    _pages.add(NotificationScreen());

    initializeServices();
    requestPermission();
    // handleCall();
    _initializeProviderConnection();
    //callSocketInit();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await callSocketInit();
      context.read<CallSocketHandleCubit>().fetchAllUsers();
    });

    context.read<PlanCubit>().fetchCurrentPlanOnly();
    context.read<UserFriendsCubit>().resetCubit();
    Future.microtask(() => Provider.of<RequestsProvider>(context, listen: false)
        .fetchRequestsCount());
    fetchBooksAndUpdateGrid();
  }

  void _initializeProviderConnection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callSocketCubit = context.read<CallSocketHandleCubit>();
      final remainingMinutesProvider =
          Provider.of<RemainingMinutesProvider>(context, listen: false);

      // Set the provider in cubit
      callSocketCubit.setRemainingMinutesProvider(remainingMinutesProvider);

      // Request initial minutes
      callSocketCubit.requestRemainingMinutes();
    });
  }

  Future<void> _initializeProfileProvider() async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.initialize();
  }

  Future<bool> requestPermission() async {
    var status = await Permission.phone.request();

    return switch (status) {
      PermissionStatus.denied ||
      PermissionStatus.restricted ||
      PermissionStatus.limited ||
      PermissionStatus.permanentlyDenied =>
        false,
      PermissionStatus.provisional || PermissionStatus.granted => true,
    };
  }
  //
  // void handleCall() {
  //   FlutterCallkitIncoming.onEvent.listen((event) {
  //     print('Calling Listen: ${event?.event}');
  //
  //
  //     if (event?.event == Event.actionCallAccept) {
  //       Map<String, dynamic> data = event?.body ?? {};
  //
  //       if (currentUserId != '') {
  //         int target = int.parse(data["extra"]['userId'] ?? "0");
  //
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => VoiceCallScreen(
  //                 callerId: target,
  //                 callerName: "${data['nameCaller']}",
  //                 callerImage: '',
  //                 isIncoming: false),
  //           ),
  //         );
  //       }
  //     } else if (event?.event == Event.actionCallDecline) {
  //       Map<String, dynamic> data = event?.body ?? {};
  //       int target = int.parse(data["extra"]['userId'] ?? "0");
  //       context.read<CallSocketHandleCubit>().endCall();
  //     } else if (event?.event == Event.actionCallEnded) {}
  //   });
  // }

  Future<void> callSocketInit() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("user_id");
    currentUserId = userId;
    int? profileProvider =
        userId != null && userId != '' ? int.parse(userId) : null;
    if (profileProvider != null) {
      final cubit = context.read<CallSocketHandleCubit>();

      await cubit.initCallSocket(); // wait for initialization
      Future.delayed(Duration(seconds: 2), () {
        if (!mounted) return;
        context.read<CallSocketHandleCubit>().listenEvent("call-ended", (data) {
          if (!mounted) return;
          CallTimerState state = context.read<CallTimerCubit>().state;
        });
      });
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> initializeServices() async {
    try {
      // Initialize API service
      apiService = await ApiService.create();

      // Fetch profile details
      final userResponse = await apiService!.fetchProfileDetails();

      // Update ProfileProvider with the fetched data
      if (mounted) {
        final profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);
        await profileProvider.updateProfile(userResponse.user);
        final userDetails = profileProvider.fetchProfile();
        print('Languages da: ${userResponse.user.speakingLanguage}');
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

  Future<void> fetchBooksAndUpdateGrid() async {
    setState(() => _isBooksLoading = true);
    try {
      final apiService = await ApiService.create();
      BookResponse bookResponse = await apiService.fetchBooks();

      if (!bookResponse.hasData) {
        print("⚠️ No books data received");
        setState(() => _isBooksLoading = false);
        return;
      }

      print("✅ Fetched ${bookResponse.data.length} books from API");

      setState(() {
        _gridItems.clear();

        final gradients = [
          LinearGradient(
            colors: [Colors.cyan, Colors.indigo],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          LinearGradient(
            colors: [Color(0xFFDA90FF), Color(0xFF861FBA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          LinearGradient(
            colors: [Color(0xFFFF999B), Color(0xFFA62426)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          LinearGradient(
            colors: [Color(0xFFFFE09D), Color(0xFFE9A004)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          LinearGradient(
            colors: [Color(0xFFFF96FF), Color(0xFFAD07AD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          LinearGradient(
            colors: [Color(0xFF89D4FF), Color(0xFF1976D2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          LinearGradient(
            colors: [Color(0xFF8B8BC4), Color(0xFF8B8BC4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ];

        for (int i = 0; i < bookResponse.data.length; i++) {
          final book = bookResponse.data[i];
          final imagePath = book.booksImage ?? '';
          final imageUrl = imagePath.startsWith('/')
              ? 'https://picturoenglish.com/admin${imagePath}'
              : 'https://picturoenglish.com/admin/$imagePath';

          _gridItems.add({
            'id': book.id,
            'image': imageUrl,
            'text': book.booksName,
            'gradient': gradients[i % gradients.length],
            'isFromApi': true,
            'isComingSoon': book.isComingSoon,
            'page': book.isComingSoon
                ? null
                : TopicsScreen(
                    title: book.booksName,
                    topicId: book.id,
                  ),
          });
        }

        _isBooksLoading = false;
        _pages[0] = HomeContent(gridItems: _gridItems);
      });
    } catch (e) {
      print("❌ Error fetching books: $e");
      setState(() => _isBooksLoading = false);
    }
  }

  void _setDefaultGridItems() {
    setState(() {
      _gridItems = [
        {
          'image': 'assets/verbs.png',
          'text': 'Verb',
          'gradient': LinearGradient(
            colors: [Colors.cyan, Colors.indigo],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          'page': TopicsScreen(title: 'Verbs', topicId: 1),
          'isFromApi': false,
        },
        {
          'image': 'assets/adverb.png',
          'text': 'Adverb',
          'gradient': LinearGradient(
            colors: [Color(0xFFDA90FF), Color(0xFF861FBA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          'page': TopicsScreen(title: 'Adverbs', topicId: 2),
          'isFromApi': false,
        },
        {
          'image': 'assets/waiting.png',
          'text': 'Coming Soon',
          'gradient': LinearGradient(
            colors: [Color(0xFF8B8BC4), Color(0xFF8B8BC4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          'isFromApi': false,
        },
      ];
    });
  }

  Future<bool> onWillPop() async {
    DateTime now = DateTime.now();
    if (lastPressed == null ||
        now.difference(lastPressed!) > Duration(seconds: 2)) {
      lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Press back again to exit')),
      );
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('AppLifecycleState changed to: $state');

    if (state == AppLifecycleState.paused) {
      // App is backgrounded
      // context.read<CallSocketHandleCubit>().endCall();
    } else if (state == AppLifecycleState.detached) {
      // App is about to be destroyed (on Android)
      context.read<CallSocketHandleCubit>().endCall();
    }
    // Optional: handle other states
    // else if (state == AppLifecycleState.resumed) {}
    // else if (state == AppLifecycleState.inactive) {}
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
      final bool isOnline = connectivityService.isOnline;

      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => NotificationCubit(),
          )
        ],
        child:
            BlocBuilder<BottomNavigatorIndexCubit, BottomNavigatorIndexState>(
          builder: (context, bottomNavState) {
            if (bottomNavState is BottomNavigatorIndexInitial) {
              return StreamBuilder<PhoneState>(
                  stream: PhoneState
                      .stream, // assuming this is a Stream<PhoneState>
                  builder: (context, snapshot) {
                    final state = snapshot.data;

                    if (snapshot.connectionState == ConnectionState.active &&
                        state != null) {
                      // Perform logic based on new PhoneState
                      if (state.status == PhoneStateStatus.CALL_STARTED) {
                        // Example: Start a timer
                        context
                            .read<CallSocketHandleCubit>()
                            .onNativeCallStart();
                        // context.read<CallTimerCubit>().startTimer();
                      } else if (state.status == PhoneStateStatus.CALL_ENDED) {
                        context.read<CallSocketHandleCubit>().onNativeCallEnd();
                      }
                    }
                    return WillPopScope(
                      onWillPop: onWillPop,
                      child: Scaffold(
                        backgroundColor: Color(0xFFE0F7FF),
                        body: Column(
                          children: [
                            const _OngoingCallBanner(),
                            Expanded(child: _pages[bottomNavState.selectedIndex]),
                          ],
                        ),
                        bottomNavigationBar: BottomNavigationBar(
                          type: BottomNavigationBarType.fixed,
                          backgroundColor: Colors.white,
                          currentIndex: bottomNavState.selectedIndex,
                          onTap: (index) {
                            context
                                .read<BottomNavigatorIndexCubit>()
                                .onChageIndex(index);
                          },
                          items: List.generate(4, (index) {
                            return BottomNavigationBarItem(
                              icon: index == 3
                                  ? Consumer<RequestsProvider>(
                                      builder: (context, requestsProvider, _) {
                                        int count =
                                            requestsProvider.requestsCount;
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Image.asset(
                                              bottomNavState.selectedIndex ==
                                                      index
                                                  ? _navIconsSelected[index]
                                                  : _navIcons[index],
                                              width: 23,
                                              height: 28,
                                              color: bottomNavState
                                                          .selectedIndex ==
                                                      index
                                                  ? Color(0xFF49329A)
                                                      .withValues(alpha: .8)
                                                  : Colors.grey.shade500,
                                            ),
                                            if (count > 0)
                                              Positioned(
                                                right: -6,
                                                top: -4,
                                                child: Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  constraints: BoxConstraints(
                                                      minWidth: 18,
                                                      minHeight: 18),
                                                  child: Center(
                                                    child: Text(
                                                      '$count',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontFamily: AppConstants.commonFont,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    )
                                  // : index == 1
                                  //   ? Consumer<UnreadCountProvider>(
                                  //       builder: (context, unreadCountProvider, _) {
                                  //         int unread = unreadCountProvider.totalUnreadCount;
                                  //         return Stack(
                                  //           clipBehavior: Clip.none,
                                  //           children: [
                                  //             Image.asset(
                                  //             bottomNavState.selectedIndex == index
                                  //                 ? _navIconsSelected[index]
                                  //                 : _navIcons[index],
                                  //             width: 23,
                                  //             height: 28,
                                  //             color: bottomNavState.selectedIndex == index
                                  //                 ? Color(0xFF49329A).withValues(alpha: .8)
                                  //                 : Colors.grey.shade500,
                                  //           ),
                                  //             if (unread > 0)
                                  //               Positioned(
                                  //                 right: -6,
                                  //                 top: -4,
                                  //                 child: Container(
                                  //                   padding: EdgeInsets.all(4),
                                  //                   decoration: BoxDecoration(
                                  //                     color: Colors.green,
                                  //                     shape: BoxShape.circle,
                                  //                   ),
                                  //                   constraints:
                                  //                       BoxConstraints(minWidth: 18, minHeight: 18),
                                  //                   child: Center(
                                  //                     child: Text(
                                  //                       '$unread',
                                  //                       style: TextStyle(
                                  //                         color: Colors.white,
                                  //                         fontSize: 10,
                                  //                         fontWeight: FontWeight.bold,
                                  //                       ),
                                  //                     ),
                                  //                   ),
                                  //                 ),
                                  //               ),
                                  //           ],
                                  //         );
                                  //       },
                                  //     )
                                  : Image.asset(
                                      bottomNavState.selectedIndex == index
                                          ? _navIconsSelected[index]
                                          : _navIcons[index],
                                      width: 23,
                                      height: 28,
                                      color:
                                          bottomNavState.selectedIndex == index
                                              ? Color(0xFF49329A)
                                                  .withValues(alpha: .8)
                                              : Colors.grey.shade500,
                                    ),
                              label: _navLabels[index],
                            );
                          }),
                          selectedItemColor: Color(0xFF49329A),
                          selectedLabelStyle:
                              TextStyle(fontWeight: FontWeight.w800,fontFamily: AppConstants.commonFont),
                          unselectedFontSize: 13,
                          unselectedLabelStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: AppConstants.commonFont,
                              fontWeight: FontWeight.w700),
                          unselectedItemColor: Colors.grey,
                        ),
                        floatingActionButton:
                            (bottomNavState.selectedIndex == 0 && isOnline)
                                ? ClipOval(
                                    child: Material(
                                      color: Color(0xFF49329A),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ChatBotScreen()),
                                          );
                                        },
                                        child: Container(
                                          width: 45,
                                          height: 45,
                                          alignment: Alignment.center,
                                          child: Image.asset(
                                            'assets/fluent_bot-28-filled.png',
                                            width: 28,
                                            height: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                        floatingActionButtonLocation: isOnline
                            ? FloatingActionButtonLocation.endFloat
                            : null,
                      ),
                    );
                  });
            } else {
              return Scaffold();
            }
          },
        ),
      );
    });
  }
}

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
    context.read<CoinCubit>().setCoin(100);
    connectSocket();
  }

  Future<void> connectSocket() async {
    // Re-initialize ChatSocket with UserStatusCubit (important after logout/login)
    ChatSocket.init(context.read<UserStatusCubit>());
    await ChatSocket.connectSocket();
  }

  Widget _buildBookImage(
      String imageUrl, bool isFromApi, String bookTitle, int bookId) {
    if (bookTitle == 'Coming Soon') {
      return Center(
        child: Icon(
          Icons.lock,
          size: 30,
          color: Colors.white,
        ),
      );
    }

    if (isFromApi && imageUrl.startsWith('http')) {
      print("🖼️ Loading network image for $bookTitle: $imageUrl");
      return Image.network(
        imageUrl,
        key: ValueKey('img_$bookId'),
        height: 55,
        width: 55,
        fit: BoxFit.cover,
        headers: {
          'Cache-Control': 'no-cache',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print("✅ Image loaded for $bookTitle");
            return child;
          }
          return Center(
            child: SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print("❌ Error loading image for $bookTitle ($imageUrl): $error");
          return Container(
            color: Colors.white.withOpacity(0.3),
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white,
              size: 30,
            ),
          );
        },
      );
    } else {
      return Image.asset(
        imageUrl,
        key: ValueKey('asset_$bookId'),
        height: 55,
        width: 55,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.white.withOpacity(0.3),
            child: Icon(
              Icons.book,
              color: Colors.white,
              size: 30,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? lastPressed;

    Future<bool> onWillPop() async {
      DateTime now = DateTime.now();
      if (lastPressed == null ||
          now.difference(lastPressed!) > Duration(seconds: 2)) {
        lastPressed = now;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Press back again to exit')),
        );
        return false;
      }
      return true;
    }

    return Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
      final bool isOnline = connectivityService.isOnline;

      return Stack(
        children: [
          WillPopScope(
            onWillPop: onWillPop,
            child: Scaffold(
              backgroundColor: Color(0xFFE0F7FF),
              appBar: CommonAppBar(
                title: "Home",
                isFromHomePage: true,
              ),
              body: FutureBuilder(
                future: Future.value(widget.gridItems),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error loading data"));
                  } else {
                    List<Map<String, dynamic>> items =
                        snapshot.data as List<Map<String, dynamic>>;

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const HomeSkeletonLoader();
                    }

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
                              padding:
                                  EdgeInsets.only(left: 24, right: 24, top: 5),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                var gridItem = items[index];
                                final isFromApi =
                                    gridItem['isFromApi'] ?? false;
                                final imageUrl = gridItem['image'] ?? '';
                                final bookId = gridItem['id'] ?? index;
                                final bookTitle = gridItem['text'] ?? '';

                                return GestureDetector(
                                  key: ValueKey('book_$bookId'),
                                  onTap: () {
                                    if (bookTitle == 'Coming Soon') {
                                      return;
                                    }
                                    if (gridItem['page'] != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                gridItem['page']),
                                      );
                                    }
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: gridItem['gradient'],
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 18, top: 8, bottom: 8),
                                          child: Container(
                                            height: 55,
                                            width: 55,
                                            alignment: Alignment.center,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: _buildBookImage(
                                                imageUrl,
                                                isFromApi,
                                                bookTitle,
                                                bookId,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 15),
                                        Expanded(
                                          child: Text(
                                            capitalizeFirstLetter(bookTitle),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontFamily:
                                                  AppConstants.commonFont,
                                              fontWeight:
                                                  (bookTitle == 'Coming Soon')
                                                      ? FontWeight.w500
                                                      : FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
          ),
          if (!isOnline) const OfflineOverlay(),
        ],
      );
    });
  }
}

class _OngoingCallBanner extends StatelessWidget {
  const _OngoingCallBanner();

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallSocketHandleCubit, CallSocketHandleState>(
      builder: (context, callState) {
        final callCubit = context.read<CallSocketHandleCubit>();
        if (!callCubit.isLiveCallActive) return const SizedBox.shrink();

        return BlocBuilder<CallTimerCubit, CallTimerState>(
          builder: (context, timerState) {
            final name = callCubit.callerName ?? 'Unknown';
            final duration = _formatDuration(timerState.duration);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceCallScreen(
                      callerId: callCubit.targetUserId ?? 0,
                      callerName: name,
                      callerImage: '',
                      isIncoming: false,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                color: const Color(0xFF1A7A4A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.call, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            duration,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<CallSocketHandleCubit>().endCall();
                        context.read<CallTimerCubit>().resetTimer();
                        context.read<AudioSettingsProvider>().reset();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'End',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 10),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            height: 75,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
