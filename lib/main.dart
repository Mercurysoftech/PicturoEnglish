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
import 'package:picturo_app/classes/services/typing_state_manager.dart';
import 'package:picturo_app/cubits/premium_cubit/premium_plans_cubit.dart';
import 'package:picturo_app/cubits/referal_cubit/referal_cubit.dart';
import 'package:picturo_app/providers/bankaccountprovider.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/providers/userprovider.dart';
import 'package:picturo_app/screens/chatscreenpage.dart';
import 'package:picturo_app/screens/splashscreenpage.dart';
import 'package:picturo_app/screens/voicecallscreen.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/services/global_service.dart';
import 'package:picturo_app/services/navigation_service.dart';
import 'package:picturo_app/services/push_notification_service.dart';
import 'package:picturo_app/services/socket_notifications_service.dart';
import 'package:picturo_app/socket/socketservice.dart';
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
      final receiverId = int.tryParse(message.data['receiver_id']?.toString() ?? "0") ?? 0;    

      showFlutterCallNotification(
          callSessionId: 'sdkjcslkcmslkcmsdc',
          userId: callerId.toString(),
          callerName: callerName,
          callerId: callerId,
          receiverId: receiverId,
        );
    } else {
      log("💬 Background chat notification received");
      //PushNotificationService.showNotification(message);
    }
  } catch (e) {
    log("⚠️ Error in background handler: $e");
  }
}



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

  await setupFlutterNotifications();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().requestPermissions();
  PushNotificationService.initialize();
  await SocketNotificationsService.initialize();
  //await globalSocketService.initialize();
  //WidgetsBinding.instance.addObserver(AppLifecycleObserver());

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Register plugins in background isolate
  FlutterCallkitIncoming.onEvent.listen((event) async {
    log("📞 CallKit event received: ${event?.event}");

    if (event?.event == Event.actionCallAccept) {
      log("✅ Call accepted via CallKit");
      final data = event?.body ?? {};
      final target = int.parse(data["extra"]['userId'] ?? "0");
      final cubit = NavigationService.instance.navigationKey.currentContext?.read<CallSocketHandleCubit>();

      if (cubit == null) {
        log("⚠️ Call cubit not available");
        return;
      }

      if (cubit.isLiveCallActive) {
        log("⚠️ Call already active - ignoring duplicate");
        return;
      }


      Navigator.push(
        NavigationService.instance.navigationKey.currentContext!,
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
     // Extract caller and receiver IDs from the call data
    final data = event?.body ?? {};
    final callerId = int.tryParse(data["extra"]['callerId']?.toString() ?? "0") ?? 0;
    final receiverId = int.tryParse(data["extra"]['receiverId']?.toString() ?? "0") ?? 0;
    
    // Make API call to reject the call
    try {
      final apiService = await ApiService.create();
      final result = await apiService.rejectCall(callerId);
      
      if (result['status'] == true) {
        log("✅ Call rejection API call successful: ${result['message']}");
      } else {
        log("⚠️ Call rejection API call failed: ${result['message']}");
      }
    } catch (e) {
      log("❌ Error making reject call API: $e");
    }
    
    // End the call locally
    NavigationService.instance.navigationKey.currentContext?.read<CallSocketHandleCubit>().endCall();
    }
  });



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
        ChangeNotifierProvider(create: (_) => TypingStateManager()),
        BlocProvider(create: (context) => CallSocketHandleCubit()..initCallSocket()),
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

      } else {
        log("💬 Handling chat notification navigation");
        final senderName = data['username']?.toString() ?? "Unknown";
        final profilePicId =
            int.tryParse(data['avatar_id']?.toString() ?? "0") ?? 0;
        final userId = int.tryParse(data['sender_id']?.toString() ?? "0") ?? 0;

        Navigator.of(NavigationService.instance.navigationKey.currentContext!).pushAndRemoveUntil(
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
  String? callerName;
  int? targetId;
  Future<Map<String,dynamic>?> getCurrentCall() async {
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        bool accepted = calls[0]['accepted'];

        if (accepted) {
          setState(() {
            callConnectd=true;
            callerName=calls[0]['nameCaller'];
             targetId = int.parse(calls[0]["extra"]['userId'] ?? "0");
            _currentUuid = calls[0]['id'];
          });
          FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");
        }else{
          FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");
        }

        return calls[0];
      } else {
        _currentUuid = "";
        return null;
      }
    }
    return null;
  }
  bool callConnectd=false;
  Future<void> checkAndNavigationCallingPage() async {

    Map<String,dynamic>? currentCall = await getCurrentCall();

    BuildContext? contextx=NavigationService.instance.navigationKey.currentContext;
    if(contextx!=null){
      if(currentCall!=null){

     Future.delayed(Duration.zero,(){
       if(contextx.mounted){
         int target = int.parse(currentCall["extra"]['userId'] ?? "0");

         Navigator.push(
           contextx,
           MaterialPageRoute(
             builder: (context) => VoiceCallScreen(
                 callerId: target,
                 callerName: "${currentCall['nameCaller']}",
                 callerImage: '',
                 isIncoming: false),
           ),
         );
       }

     });
      }
    }else{
      if (currentCall != null) {
        bool accepted=currentCall['accepted'];

        if(accepted){


            setState(() {
              callConnectd=true;
            });


          Future.delayed(const Duration(seconds: 2),()async{

            callConnectd=false;
            _currentUuid='';
            setState(() {

            });
          });

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
        navigatorKey:NavigationService.instance.navigationKey,
        debugShowCheckedModeBanner: false,
          home: (_currentUuid!=null&&_currentUuid!='')?(callConnectd)?
          VoiceCallScreen(
              callerId: targetId??0,
              callerName: "${callerName}",
              callerImage: '',
              isIncoming: false)
              :const LoadedrSatste():
          const SplashScreen())
    );
  }
}
class LoadedrSatste extends StatefulWidget {
  const LoadedrSatste({super.key});

  @override
  State<LoadedrSatste> createState() => _LoadedrSatsteState();
}

class _LoadedrSatsteState extends State<LoadedrSatste> {

  @override
  void initState() {

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
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

class ChatScreenTracker {
  static String? activeChatUserId;

    static bool isInChatWithUser(String userId) {
    return activeChatUserId == userId;
  }
}


// class AppLifecycleObserver extends WidgetsBindingObserver {
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     switch (state) {
//       case AppLifecycleState.resumed:
//         globalSocketService.setAppState(true);
//         log('📱 App in foreground');
//         break;
//       case AppLifecycleState.inactive:
//       case AppLifecycleState.paused:
//       case AppLifecycleState.detached:
//         globalSocketService.setAppState(false);
//         log('📱 App in background');
//         break;
//       case AppLifecycleState.hidden:
//       log('📱 App is hidden');
//         break;
//     }
//   }
// }
