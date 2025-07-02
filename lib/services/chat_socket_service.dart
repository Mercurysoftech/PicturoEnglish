import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
class ChatSocket {
  static   late IO.Socket socket;
  static Future<void> connectScoket()async{
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    socket = IO.io('https://picturoenglish.com:2025', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    socket.onConnect((_) {
      print("Connect jjjjj  ${ {
        "user_id": userId,
        "fcm_token": "$token"
      }}");
      socket.emit('register', {
        "user_id": userId,
        "fcm_token": token
      });
    });
    socket.on('register', (data) {

    });
 }

 static void dispose(){
    socket.dispose();
 }
}