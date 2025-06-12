import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:picturo_app/classes/services/notification_service.dart';
import 'package:picturo_app/providers/bankaccountprovider.dart';
import 'package:picturo_app/providers/profileprovider.dart';
import 'package:picturo_app/providers/userprovider.dart';
import 'package:picturo_app/screens/actionsnappage.dart';
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
import 'package:picturo_app/services/push_notification_service.dart';
import 'package:picturo_app/socket/socketservice.dart';
import 'package:picturo_app/utils/common_file.dart';
import 'package:provider/provider.dart';

import 'cubits/call_cubit/call_duration_handler/call_duration_handle_cubit.dart';
import 'cubits/call_cubit/call_socket_handle_cubit.dart';
import 'cubits/call_log_his_cubit/call_log_cubit.dart';
import 'cubits/content_view_per_get/content_view_percentage_cubit.dart';
import 'cubits/drag_and_learn_cubit/drag_and_learn_cubit.dart';
import 'cubits/faq_details_cubit/faq_details_cubit.dart';
import 'cubits/game_view_cubit/game_view_cubit.dart';
import 'cubits/games_cubits/quest_game/quest_game_qtn_list_cubit.dart';
import 'cubits/get_avatar_cubit/get_avatar_cubit.dart';
import 'cubits/get_sub_topics_list/get_sub_topics_list_cubit.dart';
import 'cubits/get_topics_list_cubit/get_topic_list_cubit.dart';
import 'cubits/get_user_helper_messages/get_user_helper_msg_cubit.dart';
import 'cubits/helper_user_message_cubit/helper_user_message_cubit.dart';
import 'cubits/user_friends_cubit/user_friends_cubit.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Handling background message: ${message.messageId}");
}
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  initLocalNotification();
  await NotificationService().init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions
  await NotificationService().requestPermissions();
  
  // Initialize notifications
  await _initializeNotifications();
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

      ],
      child: MyApp(),
    ),
  );
}
Future<void> initLocalNotification() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher'); // make sure the icon exists

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {

      //   if (response.actionId == 'ongoing_call_channel') {
      //         stopCallDurationNotification();
      //         Map<String,dynamic> msgData= jsonDecode(response.payload??"{}");
      //         Call call=Call.fromMap(msgData);
      //         BuildContext? context=NavigationService.instance.navigationKey.currentContext;
      //         if(context!=null){
      //           Navigator.push(context, MaterialPageRoute(builder: (context)=>CometchatCallMainPage(isAudioOnly: false, sessionId:call.sessionId==null?'': call.sessionId.toString(),)));
      //         }else{
      //           NavigationService.instance.pushNamedIfNotCurrent(AppRoute.callingPage, args:call.sessionId);
      //         }
      //         // 🚨 Hangup clicked!
      //       }else{
      //         Map<String,dynamic> msgData= jsonDecode(response.payload??"{}");
      //
      //         RemoteMessage gg=RemoteMessage.fromMap(msgData);
      //         openNotification(gg, NavigationService.instance.navigationKey);
      //       }
      // Navigate or perform action
    },
  );
}
Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: initializationSettingsAndroid,
    ),
  );
}
class DraggableFloatingButton extends StatefulWidget {
  final VoidCallback onTap;

  const DraggableFloatingButton({super.key, required this.onTap});

  @override
  _DraggableFloatingButtonState createState() => _DraggableFloatingButtonState();
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
            final callCubit = BlocProvider.of<CallSocketHandleCubit>(context, listen: true);
            final isActive = callCubit.isLiveCallActive;

            return (isActive)?InkWell(
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VoiceCallScreen( callerId:context.watch<CallSocketHandleCubit>().targetUserId??0,callerName: "Testd", callerImage:'',isIncoming: false),
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
                          style: TextStyle(fontFamily: AppConstants.commonFont,fontSize: 16, color: Colors.green),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ):SizedBox();
          },
        ),
      ),
    );
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    PushNotificationService.initialize(context); // Important!

    return BlocProvider(
  create: (context) => TopicCubit(),
  child: MaterialApp(
      navigatorKey: navigatorKey,
      // builder: (context, child) {
      //   return Stack(
      //     children: [
      //       child!,
      //       DraggableFloatingButton(
      //         onTap: () {
      //           final currentContext = navigatorKey.currentContext;
      //           if (currentContext != null) {
      //             ScaffoldMessenger.of(currentContext).showSnackBar(
      //               const SnackBar(content: Text('Floating button tapped!')),
      //             );
      //           }
      //         },
      //       ),
      //     ],
      //   );
      // },
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/homepage': (context) => Homepage(),
        '/signup': (context) => Signupscreen(),
        '/gender&age':(context)=> GenderAgeScreen(),
        '/gamespage':(context)=>GamesPage(),
        '/profile':(context)=> MyProfileScreen(),
        '/location':(context)=> LocationGetPage(isFromProfile: false,),
        '/language':(context)=> LanguageSelectionApp(),
      },
    ),
);
  }
}
String capitalizeFirstLetter(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}