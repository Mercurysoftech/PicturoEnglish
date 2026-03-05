import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:picturo_app/classes/helper/bot_calls_refresh.dart';
import 'package:picturo_app/classes/helper/call_info_storage_helper.dart';
import 'package:picturo_app/classes/services/connectivity_service.dart';
import 'package:picturo_app/classes/services/notification_service.dart';
import 'package:picturo_app/classes/services/typing_state_manager.dart';
import 'package:picturo_app/cubits/call_controls/call_controls_cubit.dart';
import 'package:picturo_app/cubits/premium_cubit/premium_plans_cubit.dart';
import 'package:picturo_app/cubits/referal_cubit/referal_cubit.dart';
import 'package:picturo_app/cubits/user_status/user_status_cubit.dart';
import 'package:picturo_app/providers/audiosettingsprovider.dart';
import 'package:picturo_app/providers/bankaccountprovider.dart';
import 'package:picturo_app/providers/online_status_provider.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/providers/remaining_bot_calls_provider.dart';
import 'package:picturo_app/providers/remaining_minutes_provider.dart';
import 'package:picturo_app/providers/requests_provider.dart';
import 'package:picturo_app/providers/unread_count_provider.dart';
import 'package:picturo_app/providers/userprovider.dart';
import 'package:picturo_app/screens/chatscreenpage.dart';
import 'package:picturo_app/screens/earnings_ref/referral_details.dart';
import 'package:picturo_app/screens/homepage.dart';
import 'package:picturo_app/screens/premiumscreenpage.dart';
import 'package:picturo_app/screens/splashscreenpage.dart';
import 'package:picturo_app/screens/voicecallscreen.dart';
import 'package:picturo_app/services/api_service.dart';
import 'package:picturo_app/services/app_lifecycle_manager.dart';
import 'package:picturo_app/services/applifecycleservice.dart';
import 'package:picturo_app/services/call_foreground_service.dart';
import 'package:picturo_app/services/chat_socket_service.dart';
import 'package:picturo_app/services/global_service.dart';
import 'package:picturo_app/services/navigation_service.dart';
import 'package:picturo_app/services/push_notification_service.dart';
import 'package:picturo_app/services/socket_notifications_service.dart';
import 'package:picturo_app/socket/socketservice.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/main.dart';

import 'package:picturo_app/classes/callkit_session.dart';
import 'package:picturo_app/classes/helper/native_call_listener.dart';
import 'package:picturo_app/classes/helper/android_callkit_listener.dart';
import 'package:picturo_app/services/callkit_service.dart';
import 'package:picturo_app/services/native_channel_helper.dart';

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
  if (Platform.isIOS) return; // iOS uses PushKit/CallKit natively via AppDelegate
  log("📲 Background message received: ${message.data}");

  try {
    if (message.data['type'] == 'incoming_call') {
      log("📞 Background call notification received");
      //await _showCallNotification(message.data);

      final callerId =
          int.tryParse(message.data['caller_id']?.toString() ?? "0") ?? 0;
      final callerName =
          message.data['caller_username']?.toString() ?? "Unknown";
      final receiverId =
          int.tryParse(message.data['receiver_id']?.toString() ?? "0") ?? 0;

      await CallInfoStorage.saveCallInfo(
        callerId: callerId,
        callerName: callerName,
        isIncoming: true,
      );

      FlutterCallkitIncoming.onEvent.listen((event) async {
        log("📞 Background CallKit event: ${event?.event}");

        if (event?.event == Event.actionCallDecline) {
          log("❌ Background call declined via CallKit");

          try {
            final apiService = await ApiService.create();
            final result = await apiService.rejectCall(callerId, receiverId);

            if (result['status'] == true) {
              log("✅ Background call rejection API successful: ${result['message']}");
            } else {
              log("⚠️ Background call rejection API failed: ${result['message']}");
            }
          } catch (e) {
            log("❌ Error making background reject call API: $e");
          }

          await FlutterCallkitIncoming.endAllCalls();
        }
      });

      await CallKitService.showIncoming(
        callerName: callerName,
        userId: callerId.toString(),
        callerId: callerId,
        receiverId: receiverId,
      );
    } else if (message.data['type'] == 'end_call' ||
        message.data['type'] == 'call-ended' ||
        message.data['type'] == 'missed_call' ||
        message.data['type'] == 'Missed Call') {
      log("📞 Background outgoing call notification received");
      await FlutterCallkitIncoming.endAllCalls();
    } else if (message.data['type'] == 'refer') {
      log("📞 Background referral notification received");

      await flutterLocalNotificationsPlugin.show(
        0,
        "Referral Bonus 🎁",
        "Tap to view your premium plans!",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'refer_channel',
            'Referral Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode({"type": "refer"}),
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
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        log('🔔 Notification tapped with payload: ${response.payload}');
      }
    },
  );
}

Future<void> _handleCallOnError() async {
  try {
    // Try to end any active call when error occurs
    await FlutterCallkitIncoming.endAllCalls();

    // Notify server about unexpected call ending
    final prefs = await SharedPreferences.getInstance();
    final hadActiveCall = prefs.getBool('last_active_call') ?? false;

    if (hadActiveCall) {
      final apiService = await ApiService.create();
      final userId = prefs.getString('user_id');
      final targetId = prefs.getString('last_call_target_id');

      if (userId != null && targetId != null) {
        await apiService.rejectCall(
          int.parse(userId),
          int.parse(targetId),
        );
      }
    }
  } catch (e) {
    log('❌ Error in error handler: $e');
  }
}

String? initialNotificationPayload;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //await AppLifecycleManager().initialize();

  await ForegroundService().initializeService();

  final ongoingCall = await ForegroundService().getOngoingCallData();

  FlutterError.onError = (details) {
    log('🚨 FLUTTER ERROR: ${details.exception}');
    log('Stack trace: ${details.stack}');

    _handleCallOnError();
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log('🚨 PLATFORM ERROR: $error');
    log('Stack trace: $stack');

    _handleCallOnError();

    return true;
  };

  await setupFlutterNotifications();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (Platform.isIOS) {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      String? apnsToken = await messaging.getAPNSToken();
      int attempts = 0;
      while (apnsToken == null && attempts < 10) {
        await Future.delayed(const Duration(seconds: 1));
        apnsToken = await messaging.getAPNSToken();
        attempts++;
      }
      if (apnsToken != null) {
        log('✅ APNs Token obtained: $apnsToken');
      } else {
        log('⚠️ APNs token not available after waiting');
      }
    } catch (e) {
      log('❌ Error getting APNs token: $e');
    }
  }

  await NotificationService().requestPermissions();
  PushNotificationService.initialize();
  await SocketNotificationsService.initialize();
  //await globalSocketService.initialize();
  //WidgetsBinding.instance.addObserver(AppLifecycleObserver());

  if (!Platform.isIOS) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Handle foreground messages (app in foreground)
  // iOS: VoIP calls are handled by AppDelegate/PushKit, not FCM foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (Platform.isIOS) return;
    log("📲 Foreground message received: ${message.data}");

    try {
      if (message.data['type'] == 'incoming_call') {
        // NOTE: On Android foreground, the socket 'incoming-call' event fires simultaneously
        // and calls showFlutterCallNotification() to show the CallKit UI.
        // We must NOT also call CallKitService.showIncoming() here — that creates a SECOND
        // CallKit notification with a different UUID, causing duplicates that cancel each other.
        // Just save the call info so it's available when the socket path processes the call.
        log("📞 Foreground FCM call notification received — socket handles CallKit UI");

        final callerId =
            int.tryParse(message.data['caller_id']?.toString() ?? "0") ?? 0;
        final callerName =
            message.data['caller_username']?.toString() ?? "Unknown";

        await CallInfoStorage.saveCallInfo(
          callerId: callerId,
          callerName: callerName,
          isIncoming: true,
        );
      } else if (message.data['type'] == 'end_call' ||
          message.data['type'] == 'call-ended' ||
          message.data['type'] == 'missed_call' ||
          message.data['type'] == 'Missed Call') {
        log("📞 Foreground call end notification received");
        await FlutterCallkitIncoming.endAllCalls();
      } else if (message.data['type'] == 'refer') {
        log("🎁 Foreground referral notification received");
        // Handle referral notification if needed
      } else {
        log("💬 Foreground chat notification received");
      }
    } catch (e) {
      log("⚠️ Error in foreground handler: $e");
    }
  });

  // Request call-related permissions for Android 14+
  if (Platform.isAndroid) {
    try {
      // Request notification permission for CallKit
      await FlutterCallkitIncoming.requestNotificationPermission({
        "rationaleMessagePermission":
            "Notification permission is required to receive incoming calls.",
        "postNotificationMessageRequired":
            "Please allow notifications to receive incoming calls.",
      });

      // Request full-screen intent + overlay permissions via platform channel
      const callPermissionsChannel = MethodChannel('picturo_call_permissions');
      final missingPermissions = await callPermissionsChannel
          .invokeMethod('checkAndRequestCallPermissions');
      if (missingPermissions != null &&
          (missingPermissions as List).isNotEmpty) {
        log("⚠️ Missing call permissions: $missingPermissions");
      }
    } catch (e) {
      log("⚠️ Error requesting call permissions: $e");
    }
  }

  // NOTE: FlutterCallkitIncoming.onEvent is handled by AndroidCallKitListener.initialize()
  // (called in _MyAppState.initState). Do NOT register a second listener here — it causes
  // duplicate accept/decline handling and premature endAllCalls() dismissing the notification.

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
        ChangeNotifierProvider(create: (_) => OnlineStatusProvider()),
        ChangeNotifierProvider(create: (_) => TypingStateManager()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => RemainingBotCallsProvider()),
        ChangeNotifierProvider(create: (_) => AudioSettingsProvider()),
        ChangeNotifierProvider(create: (_) => RemainingMinutesProvider()),
        ChangeNotifierProvider(
            create: (_) => RequestsProvider()..fetchRequestsCount()),
        ChangeNotifierProvider(
            create: (_) => UnreadCountProvider()..totalUnreadCount),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              final cubit = CallSocketHandleCubit();
              cubit
                  .initCallSocket(); // no await, but executed after constructor
              return cubit;
            },
          ),
          BlocProvider(create: (context) => CallControlsCubit()),
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
          BlocProvider(create: (_) => UserStatusCubit())
        ],
        child: Builder(
          builder: (context) {
            // 👇 inject the cubit into ChatSocket
            ChatSocket.init(context.read<UserStatusCubit>());
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context
                  .read<RemainingBotCallsProvider>()
                  .fetchRemainingBotCalls();
            });
            // AppLifecycleService().initialize(
            //   onCallEnd: () async {
            //     try {
            //       await context.read<CallSocketHandleCubit>().endCall();
            //     } catch (e) {
            //       log('❌ Error in lifecycle call end: $e');
            //     }
            //   },
            // );

            return const MyApp();
          },
        ),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String? _currentUuid;
  bool _handledInitialNotification = false;
  final MethodChannel _callChannel = MethodChannel('picturo_call_service');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _handleInitialIntent();

    if (initialNotificationPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigation(initialNotificationPayload!);
        _handledInitialNotification = true;
        initialNotificationPayload = null;
      });
    }
    _initializeApp();
    checkAndNavigationCallingPage();

    // Initialize platform-specific call listeners after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Platform.isAndroid) {
        AndroidCallKitListener.initialize();
      }
      if (Platform.isIOS) {
        NativeCallListener.initialize();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isIOS) {
      CallKitSession.isAppInForeground = (state == AppLifecycleState.resumed);
    }
    if (state == AppLifecycleState.resumed) {
      _handleInitialIntent();
    }
  }

  @override
  void dispose() {
    //AppLifecycleService().dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Initialize SharedPreferences first
    final prefs = await SharedPreferences.getInstance();

    // Check if user is logged in (has auth token)
    final authToken = prefs.getString('auth_token');

    if (authToken != null && authToken.isNotEmpty) {
      // Initialize ProfileProvider if user is logged in
      final profileProvider = Provider.of<ProfileProvider>(
          NavigationService.instance.navigationKey.currentContext!,
          listen: false);

      await profileProvider.initialize();
    }
  }

  Future<void> _handleInitialIntent() async {
    try {
      //final intentData = await _callChannel.invokeMethod('getInitialIntent'); //uncommand this if gets improper calling
      final intentData = await NativeChannelHelper.invokeWithResult('getInitialIntent');
      if (intentData != null && intentData is Map) {
        final openCallScreen = intentData['open_call_screen'] == true;
        if (openCallScreen) {
          final callerName = intentData['caller_name'] ?? 'Unknown';
          final callerId = intentData['caller_id'] ?? 0;
          final isVideoCall = intentData['is_video_call'] == true;

          log("📞 Navigating from getInitialIntent: $callerName, $callerId");
          _navigateToVoiceCallScreen(callerId, callerName, isVideoCall);
          return;
        }
      }

      // If no intent data, check pending call data
      //final pendingData = await _callChannel.invokeMethod('getPendingCallData'); //uncommand this if gets improper calling
      final pendingData = await NativeChannelHelper.invokeWithResult('getPendingCallData');
      if (pendingData != null && pendingData is Map) {
        final hasPendingCall = pendingData['has_pending_call'] == true;
        if (hasPendingCall) {
          final callerName = pendingData['caller_name'] ?? 'Unknown';
          final callerId =
              int.tryParse(pendingData['caller_id']?.toString() ?? '0') ?? 0;
          final isVideoCall = pendingData['is_video_call'] == true;

          log("📞 Navigating from pending call data: $callerName, $callerId");
          _navigateToVoiceCallScreen(callerId, callerName, isVideoCall);
        }
      }
    } catch (e) {
      log('Error handling initial intent: $e');
    }
  }

  void _navigateToVoiceCallScreen(
      int callerId, String callerName, bool isVideoCall) async {
    await CallInfoStorage.saveCallInfo(
      callerId: callerId,
      callerName: callerName,
      isIncoming: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = NavigationService.instance.navigationKey.currentContext;
      if (context != null &&
          ModalRoute.of(context)?.settings.name != '/voice-call') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => VoiceCallScreen(
              callerId: callerId,
              callerName: callerName,
              callerImage: '',
              isIncoming: false,
            ),
          ),
          (route) => false,
        );
      }
    });
  }

  void _handleNotificationNavigation(String payload) async {
    log("🔄 Handling notification navigation with payload: $payload");

    await context.read<CallSocketHandleCubit>().initCallSocket();

    try {
      final data = jsonDecode(payload);

      if (data['type'] == 'incoming_call') {
      } else if (data['type'] == 'refer') {
        log("🎁 Navigating to Premium Page");
        Navigator.of(NavigationService.instance.navigationKey.currentContext!)
            .push(MaterialPageRoute(
          builder: (context) => ReferralPage(),
        ));
      } else if (data['type'] == 'end_call' ||
          data['type'] == 'call-ended' ||
          data['type'] == 'missed_call' ||
          data['type'] == 'Missed Call') {
        log("🏠 Navigating to Home after call end/missed");
        Navigator.of(NavigationService.instance.navigationKey.currentContext!)
            .pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Homepage()),
          (route) => false,
        );
      } else {
        log("💬 Handling chat notification navigation");
        final senderName = data['sender_username']?.toString() ??
            data['username']?.toString() ??
            "Unknown";
        final profilePicId =
            int.tryParse(data['avatar_id']?.toString() ?? "0") ?? 0;
        final userId = int.tryParse(data['sender_id']?.toString() ?? "0") ?? 0;

        Navigator.of(NavigationService.instance.navigationKey.currentContext!)
            .push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              avatarWidget:
                  PushNotificationService.buildUserAvatar(profilePicId),
              userName: senderName,
              userId: userId,
              profilePicId: profilePicId,
            ),
          ),
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
  Future<Map<String, dynamic>?> getCurrentCall() async {
    if (Platform.isIOS) return null; // iOS: handled by AppDelegate/NativeCallListener
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        bool accepted = calls[0]['accepted'];

        if (accepted) {
          setState(() {
            callConnectd = true;
            callerName = calls[0]['nameCaller'];
            targetId = int.parse(calls[0]["extra"]['userId'] ?? "0");
            _currentUuid = calls[0]['id'];
          });
          FlutterCallkitIncoming.endCall("sdkjcslkcmslkcmsdc");
        } else {
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

  bool callConnectd = false;
  Future<void> checkAndNavigationCallingPage() async {
    Map<String, dynamic>? currentCall = await getCurrentCall();

    BuildContext? contextx =
        NavigationService.instance.navigationKey.currentContext;
    if (contextx != null) {
      if (currentCall != null) {
        Future.delayed(Duration.zero, () {
          if (contextx.mounted) {
            int target = int.parse(currentCall["extra"]['userId'] ?? "0");
            callerName = "${currentCall['nameCaller']}";

            Navigator.push(
              contextx,
              MaterialPageRoute(
                builder: (context) => VoiceCallScreen(
                    callerId: target,
                    callerName: "${currentCall['nameCaller']}",
                    callerImage: '',
                    isIncoming: false),
              ),
            ).then((val) {
              Homepage();
            });
          }
        });
      }
    } else {
      if (currentCall != null) {
        bool accepted = currentCall['accepted'];

        if (accepted) {
          setState(() {
            callConnectd = true;
          });

          Future.delayed(const Duration(seconds: 2), () async {
            callConnectd = false;
            _currentUuid = '';
            setState(() {});
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Important!
    String initialRoute = '/';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      BotCallsRefreshService.startPeriodicRefresh(context);
    });

    // If app opened from terminated state via notification
    if (initialNotificationPayload != null) {
      initialRoute = initialNotificationPayload!; // e.g., "/chat/123"
    }

    return BlocProvider(
        create: (context) => TopicCubit(),
        child: GetMaterialApp(
            navigatorKey: NavigationService.instance.navigationKey,
            debugShowCheckedModeBanner: false,
            home: (_currentUuid != null && _currentUuid != '')
                ? (callConnectd)
                    ? VoiceCallScreen(
                        callerId: targetId ?? 0,
                        callerName: "${callerName}",
                        callerImage: '',
                        isIncoming: false)
                    : const SplashScreen()
                : const SplashScreen()));
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

  static final _remainingMinutesController = StreamController<int>.broadcast();
  static Stream<int> get remainingMinutesStream =>
      _remainingMinutesController.stream;

  static void updateRemainingMinutes(int minutes) {
    _remainingMinutesController.add(minutes);
  }

  static void dispose() {
    _remainingMinutesController.close();
  }

  static bool isInChatWithUser(String userId) => activeChatUserId == userId;
}



// class AppLifecycleService with WidgetsBindingObserver {
//   static final AppLifecycleService _instance = AppLifecycleService._internal();
  
//   factory AppLifecycleService() => _instance;
  
//   AppLifecycleService._internal();
  
//   bool _isInitialized = false;
  
//   Future<void> initialize() async {
//     if (_isInitialized) return;
    
//     WidgetsBinding.instance.addObserver(this);
//     _isInitialized = true;
    
//     // Emit online status when app starts
//     _emitOnlineStatus();
//   }
  
//   Future<void> dispose() async {
//     WidgetsBinding.instance.removeObserver(this);
//     _isInitialized = false;
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = prefs.getString('user_id');

//     switch (state) {
//       case AppLifecycleState.resumed:
//         // App is in foreground - mark online
//         _emitOnlineStatus();
//         break;

//       case AppLifecycleState.inactive:
//       case AppLifecycleState.paused:
//       case AppLifecycleState.detached:
//         // App is in background/closed - mark offline
//         _emitOfflineStatus();
//         break;

//       case AppLifecycleState.hidden:
//         // (only on web, usually safe to ignore for mobile)
//         break;
//     }
//   }

//   Future<void> _emitOnlineStatus() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('user_id');

//       if (userId != null && ChatSocket.socket?.connected == true) {
//         print('🟢 Emitting online status for user: $userId');
//         ChatSocket.socket?.emit('userOnline', {
//           'user_id': userId,
//           'is_online': true,
//         });
//          _updateLocalStatus(userId, true);
//       }
//     } catch (e) {
//       print('Error emitting online status: $e');
//     }
//   }

//   Future<void> _emitOfflineStatus() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('user_id');

//       if (userId != null && ChatSocket.socket?.connected == true) {
//         print('🔴 Emitting offline status for user: $userId');
//         ChatSocket.socket?.emit('userOffline', {
//           'user_id': userId,
//           'is_online': false,
//         });
//          _updateLocalStatus(userId, true);
//       }
//     } catch (e) {
//       print('Error emitting offline status: $e');
//     }
//   }

//   void _updateLocalStatus(String userId, bool isOnline) {
//     // Use Provider to update status locally
//     final provider = NavigationService.instance.navigationKey.currentContext
//         ?.read<OnlineStatusProvider>();
    
//     if (provider != null) {
//       provider.updateUserStatus(userId, isOnline);
//     }
//   }

//   // Call this when user explicitly logs out
//   Future<void> onUserLogout() async {
//     await _emitOfflineStatus();
//   }
// }