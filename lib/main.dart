import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:picturo_app/classes/services/notification_service.dart';
import 'package:picturo_app/cubits/premium_cubit/premium_plans_cubit.dart';
import 'package:picturo_app/cubits/referal_cubit/referal_cubit.dart';
import 'package:picturo_app/providers/bankaccountprovider.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/providers/userprovider.dart';
import 'package:picturo_app/screens/actionsnappage.dart';
import 'package:picturo_app/screens/call/calling_widget.dart';
import 'package:picturo_app/screens/call/widgets/call_receive_widget.dart';
import 'package:picturo_app/screens/chatbotpage.dart';
import 'package:picturo_app/screens/chatlistpage.dart';
import 'package:picturo_app/screens/chatscreenpage.dart';
import 'package:picturo_app/screens/chooseavatarpage.dart';
import 'package:picturo_app/screens/dragandlearnpage.dart';
import 'package:picturo_app/screens/gamespage.dart';
import 'package:picturo_app/screens/genderandagepage.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/screens/indermidiateandreasonpage.dart';
import 'package:picturo_app/screens/introduction_animation/introduction_animation_screen.dart';
import 'package:picturo_app/screens/languageselectionpage.dart';
import 'package:picturo_app/screens/learningtitlepage.dart';
import 'package:picturo_app/screens/learnwordspage.dart';
import 'package:picturo_app/screens/locationgetpage.dart';
import 'package:picturo_app/screens/loginscreen.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/screens/premiumscreenpage.dart';
import 'package:picturo_app/screens/signupscreen.dart';
import 'package:picturo_app/screens/splashscreenpage.dart';
import 'package:picturo_app/screens/voicecallscreen.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/services/global_service.dart';
import 'package:picturo_app/services/push_notification_service.dart';
import 'package:picturo_app/socket/socketservice.dart';
import 'package:picturo_app/utils/common_file.dart';
import 'package:provider/provider.dart';

import 'cubits/bottom_navigator_index_cubit.dart';
import 'cubits/call_cubit/call_duration_handler/call_duration_handle_cubit.dart';
import 'cubits/call_cubit/call_socket_handle_cubit.dart';
import 'cubits/call_cubit/get_friends_list_cubit/get_friends_list_cubit.dart';
import 'cubits/call_log_his_cubit/call_log_cubit.dart';
import 'cubits/content_view_per_get/content_view_percentage_cubit.dart';
import 'cubits/dal_level_update_cubit/dal_level_update_cubit.dart';
import 'cubits/drag_and_learn_cubit/drag_and_learn_cubit.dart';
import 'cubits/faq_details_cubit/faq_details_cubit.dart';
import 'cubits/game_view_cubit/game_view_cubit.dart';
import 'cubits/games_cubits/quest_game/quest_game_qtn_list_cubit.dart';
import 'cubits/get_avatar_cubit/get_avatar_cubit.dart';
import 'cubits/get_coins_cubit/coins_cubit.dart';
import 'cubits/get_sub_topics_list/get_sub_topics_list_cubit.dart';
import 'cubits/get_topics_list_cubit/get_topic_list_cubit.dart';
import 'cubits/get_user_helper_messages/get_user_helper_msg_cubit.dart';
import 'cubits/helper_user_message_cubit/helper_user_message_cubit.dart';
import 'cubits/user_friends_cubit/user_friends_cubit.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("📲 Background message received: ${message.data}");

  try {
    if (message.data['type'] == 'incoming_call') {
      log("📞 Background call notification received");
      //await _showCallNotification(message.data);

      final callerId =
          int.tryParse(message.data['caller_id']?.toString() ?? "0") ?? 0;
      final callerName =
          message.data['caller_username']?.toString() ?? "Unknown";

      // await flutterLocalNotificationsPlugin.show(
      //   1,
      //   "Incoming Call",
      //   "From $callerName",
      //   NotificationDetails(
      //     android: AndroidNotificationDetails(
      //       'call_channel',
      //       'Call Notifications',
      //       channelDescription: 'Incoming calls',
      //       importance: Importance.max,
      //       priority: Priority.high,
      //       playSound: true,
      //       fullScreenIntent: true,
      //     ),
      //   ),
      //   payload: jsonEncode({
      //     'type': 'incoming_call',
      //     'caller_id': callerId.toString(),
      //     'caller_username': callerName,
      //   }),
      // );

      showFlutterCallNotification(
          callSessionId: 'sdkjcslkcmslkcmsdc',
          userId: callerId.toString(),
          callerName: callerName,
        );
    } else {
      log("💬 Background chat notification received");
      _showNotification(message.data);
    }
  } catch (e) {
    log("⚠️ Error in background handler: $e");
  }
}

Future<void> _showCallNotification(Map<String, dynamic> data) async {
  log("""
📞 Showing call notification:
- Caller ID: ${data['caller_id']}
- Caller Name: ${data['caller_username']}
- Type: ${data['type']}
""");

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final androidDetails = AndroidNotificationDetails(
    'call_channel',
    'Call Notifications',
    channelDescription: 'Incoming calls',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    timeoutAfter: 60000,
    fullScreenIntent: true, 
  );

  final details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    1, 
    "Incoming Call",
    "From ${data['caller_username']}",
    details,
    payload: jsonEncode(data),
  );
}

void _showNotification(Map<String, dynamic> data) async {
  log("""
💬 Showing chat notification:
- Sender ID: ${data['sender_id']}
- Username: ${data['username']}
- Avatar ID: ${data['avatar_id']}
- Message: ${data['body']}
""");

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final bigPicture = data['avatar_url']?.isNotEmpty == true
      ? BigPictureStyleInformation(
          FilePathAndroidBitmap(data['avatar_url']),
          contentTitle: data['title'],
          summaryText: data['body'],
        )
      : null;

  final androidDetails = AndroidNotificationDetails(
    'chat_channel',
    'Chat Notifications',
    channelDescription: 'New chat messages',
    styleInformation: bigPicture,
    largeIcon: data['avatar_url']?.isNotEmpty == true
        ? FilePathAndroidBitmap(data['avatar_url'])
        : null,
    importance: Importance.high,
    priority: Priority.high,
  );

  final details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    "${data['username']} • ${data['title']}",
    data['body'],
    details,
    payload: data['deep_link'],
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> setupFlutterNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // your app icon

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

String? initialNotificationPayload;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool openedFromNotification = false;
  Map<String, dynamic>? notificationData;
  await setupFlutterNotifications();

  await NotificationService().init();
  

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? "📩 New Message",
      message.notification?.body ?? "",
      platformChannelSpecifics,
      payload: message.data['deep_link'],
    );
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await globalSocketService.initialize();
  WidgetsBinding.instance.addObserver(AppLifecycleObserver());

// FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//   log("📲 Foreground message received: ${message.data}");

//   // Skip if data is empty or invalid
//   if (message.data.isEmpty ||
//       (message.data['type'] == null && message.notification == null)) {
//     log("⚠️ Skipping empty/invalid notification");
//     return;
//   }

//   // Handle call notifications
//   if (message.data['type'] == 'incoming_call') {
//     log("📞 Foreground call notification");
//     await _showCallNotification(message.data);
//     return;
//   }

//   // Handle chat notifications - only show if not from socket
//   if (message.data['type'] != 'socket_message') {
//     log("💬 Foreground chat notification from FCM");
//     _showNotification(message.data);
//   }
// });

// // Remove the duplicate _showNotification call that was causing duplicates

//   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//     log("📱 App opened from background with notification: ${message.data}");

//     if (message.data['type'] == "chat") {
//       log("💬 Opening chat from background notification");
//       final chatId = message.data['sender_id'];
//       if (Get.currentRoute != '/chat/$chatId') {
//         Get.toNamed('/chat/$chatId');
//       }
//     } else if (message.data['type'] == "incoming_call") {
//       log("📞 Opening call from background notification");
//     }
//   });

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Register plugins in background isolate
  FlutterCallkitIncoming.onEvent.listen((event) {
    log("📞 CallKit event received: ${event?.event}");

    if (event?.event == Event.actionCallAccept) {
      log("✅ Call accepted via CallKit");
      final data = event?.body ?? {};
      final target = int.parse(data["extra"]['userId'] ?? "0");
      final cubit = navigatorKey.currentContext?.read<CallSocketHandleCubit>();

      if (cubit == null) {
        log("⚠️ Call cubit not available");
        return;
      }

      if (cubit.isLiveCallActive) {
        log("⚠️ Call already active - ignoring duplicate");
        return;
      }

      cubit.acceptCall(target);
      Navigator.push(
        navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => VoiceCallScreen(
            callerId: target,
            callerName: "${data['nameCaller']}",
            callerImage: '',
            isIncoming: false,
          ),
        ),
      );
    } else if (event?.event == Event.actionCallDecline) {
      log("❌ Call declined via CallKit");
      navigatorKey.currentContext?.read<CallSocketHandleCubit>().endCall();
    }
  });

  await NotificationService().requestPermissions();
  PushNotificationService.initialize();

  // Get the launch details (if app opened from terminated state)
  final NotificationAppLaunchDetails? launchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  if (launchDetails?.didNotificationLaunchApp ?? false) {
    initialNotificationPayload = launchDetails!.notificationResponse?.payload;
  }

  // Initialize notifications

  HttpOverrides.global = MyHttpOverrides();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BankAccountProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SocketService()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
        BlocProvider(create: (context) => CallSocketHandleCubit()),
        BlocProvider(create: (context) => DragLearnCubit()),
        BlocProvider(create: (context) => SubtopicCubit()),
        BlocProvider(create: (context) => AvatarCubit()),
        BlocProvider(create: (context) => CallLogCubit()),
        BlocProvider(create: (context) => UserFriendsCubit()),
        BlocProvider(create: (context) => GameCubit()),
        BlocProvider(create: (context) => FAQCubit()),
        BlocProvider(create: (context) => HelperUserMessageCubit()),
        BlocProvider(create: (context) => UserSupportCubit()),
        BlocProvider(create: (context) => ProgressCubit()),
        BlocProvider(create: (context) => GrammarQuestCubit()),
        BlocProvider(create: (context) => CallTimerCubit()),
        BlocProvider(create: (context) => CoinCubit()),
        BlocProvider(create: (context) => DalLevelUpdateCubit()),
        BlocProvider(create: (context) => BottomNavigatorIndexCubit()),
        BlocProvider(create: (context) => GetFriendsListCubit()),
        BlocProvider(create: (context) => PlanCubit()),
        BlocProvider(create: (context) => ReferralCubit()),
      ],
      child: MyApp(),
    ),
  );
}

class DraggableFloatingButton extends StatefulWidget {
  final VoidCallback onTap;

  const DraggableFloatingButton({super.key, required this.onTap});

  @override
  _DraggableFloatingButtonState createState() =>
      _DraggableFloatingButtonState();
}

class _DraggableFloatingButtonState extends State<DraggableFloatingButton> {
  Offset position = const Offset(20, 100);
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position += details.delta;
          });
        },
        child: BlocBuilder<CallSocketHandleCubit, CallSocketHandleState>(
          builder: (context, state) {
            final callCubit =
                BlocProvider.of<CallSocketHandleCubit>(context, listen: true);
            final isActive = callCubit.isLiveCallActive;

            return (isActive)
                ? InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VoiceCallScreen(
                              callerId: context
                                      .watch<CallSocketHandleCubit>()
                                      .targetUserId ??
                                  0,
                              callerName: "Testd",
                              callerImage: '',
                              isIncoming: false),
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
                            builder: (context, state) {
                              return Text(
                                formatDuration(state.duration),
                                style: TextStyle(
                                    fontFamily: AppConstants.commonFont,
                                    fontSize: 16,
                                    color: Colors.green),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  )
                : SizedBox();
          },
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _currentUuid;
  bool _handledInitialNotification = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (initialNotificationPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigation(initialNotificationPayload!);
        _handledInitialNotification = true;
        initialNotificationPayload = null;
      });
    }
    checkAndNavigationCallingPage();
  }

  void _handleNotificationNavigation(String payload) async {
    log("🔄 Handling notification navigation with payload: $payload");

    await context.read<CallSocketHandleCubit>().initCallSocket();

    try {
      final data = jsonDecode(payload);

      if (data['type'] == 'incoming_call') {
        log("📞 Handling incoming call notification navigation");
        final callerId =
            int.tryParse(data['caller_id']?.toString() ?? "0") ?? 0;
        final callerName = data['caller_username']?.toString() ?? "Unknown";

        if (navigatorKey.currentContext == null) {
          log("⚠️ Navigator context not available");
          return;
        }

        Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => CallAcceptScreen(
              callerName: callerName,
              avatarUrl: 0,
              callerId: callerId,
            ),
          ),
          (route) => false,
        );
      } else {
        log("💬 Handling chat notification navigation");
        final senderName = data['username']?.toString() ?? "Unknown";
        final profilePicId =
            int.tryParse(data['avatar_id']?.toString() ?? "0") ?? 0;
        final userId = int.tryParse(data['sender_id']?.toString() ?? "0") ?? 0;

        Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              avatarWidget:
                  PushNotificationService.buildUserAvatar(profilePicId),
              userName: senderName,
              userId: userId,
              profilePicId: profilePicId,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      log("⚠️ Error handling notification navigation: $e");
    }
  }

  Widget buildUserAvatar(int avatarId) {
    if (avatarId == 0) {
      return const CircleAvatar(
        radius: 25,
        backgroundColor: Color(0xFF49329A),
        backgroundImage: AssetImage('assets/avatar2.png'),
      );
    }

    return FutureBuilder<String>(
      future: _getAvatarUrl(avatarId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF49329A),
            backgroundImage: AssetImage('assets/avatar2.png'),
          );
        } else {
          return CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(snapshot.data!),
          );
        }
      },
    );
  }

  Future<String> _getAvatarUrl(int avatarId) async {
    try {
      final apiService = await ApiService.create();
      final avatarResponse = await apiService.fetchAvatars();

      final avatar = avatarResponse.data.firstWhere(
        (a) => a.id == avatarId,
        orElse: () => throw Exception('Avatar not found'),
      );

      return 'http://picturoenglish.com/admin/${avatar.avatarUrl}';
    } catch (e) {
      print('Error fetching avatar URL: $e');
      throw e;
    }
  }

  Future<dynamic> getCurrentCall() async {
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        bool accepted = calls[0]['accepted'];

        if (accepted) {
          setState(() {
            _currentUuid = calls[0]['id'];
          });
        }

        return calls[0];
      } else {
        _currentUuid = "";
        return null;
      }
    }
  }

  Future<void> checkAndNavigationCallingPage() async {
    var currentCall = await getCurrentCall();
    BuildContext? contextx = navigatorKey.currentContext;

    if (contextx != null) {
      if (currentCall != null) {
        int userCurrentId = int.parse(_currentUuid ?? "0");
        int target = int.parse(currentCall["extra"]['userId'] ?? "0");
        context.read<CallSocketHandleCubit>().acceptCall(target);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceCallScreen(
                callerId: target,
                callerName: "${currentCall['nameCaller']}",
                callerImage: '',
                isIncoming: false),
          ),
        );
      }
    } else {
      if (currentCall != null) {
        bool accepted = currentCall['accepted'];

        if (accepted) {
          int target = int.parse(currentCall["extra"]['userId'] ?? "0");
          context.read<CallSocketHandleCubit>().acceptCall(target);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoiceCallScreen(
                  callerId: target,
                  callerName: "${currentCall['nameCaller']}",
                  callerImage: '',
                  isIncoming: false),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Important!
    String initialRoute = '/';

    // If app opened from terminated state via notification
    if (initialNotificationPayload != null) {
      initialRoute = initialNotificationPayload!; // e.g., "/chat/123"
    }

    return BlocProvider(
      create: (context) => TopicCubit(),
      child: GetMaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        initialRoute: initialRoute,
        routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/homepage': (context) => Homepage(),
          '/signup': (context) => Signupscreen(),
          '/gender&age': (context) => GenderAgeScreen(),
          '/gamespage': (context) => GamesPage(),
          '/profile': (context) => MyProfileScreen(),
          '/location': (context) => LocationGetPage(
                isFromProfile: false,
              ),
          '/language': (context) => LanguageSelectionApp(),
        },
      ),
    );
  }
}

String capitalizeFirstLetter(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hive Local User')),
      body: Text("sdcsdc"),
    );
  }
}

class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        globalSocketService.setAppState(true);
        log('📱 App in foreground');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        globalSocketService.setAppState(false);
        log('📱 App in background');
        break;
      case AppLifecycleState.hidden:
      log('📱 App is hidden');
        break;
    }
  }
}
