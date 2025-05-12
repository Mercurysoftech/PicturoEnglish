import 'dart:io';

import 'package:flutter/material.dart';
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
import 'package:picturo_app/screens/languageselectionpage.dart';
import 'package:picturo_app/screens/learningtitlepage.dart';
import 'package:picturo_app/screens/learnwordspage.dart';
import 'package:picturo_app/screens/locationgetpage.dart';
import 'package:picturo_app/screens/loginscreen.dart';
import 'package:picturo_app/screens/myprofilepage.dart';
import 'package:picturo_app/screens/premiumscreenpage.dart';
import 'package:picturo_app/screens/signupscreen.dart';
import 'package:picturo_app/screens/splashscreenpage.dart';
import 'package:picturo_app/socket/socketservice.dart';
import 'package:provider/provider.dart';

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
  
  await NotificationService().init();
  
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
      ],
      child: MyApp(),
    ),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/location':(context)=> LocationGetPage(),
        '/language':(context)=> LanguageSelectionApp(),
      }
    );
  }
}
