import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gcc/Admin/Adminorderrequests.dart';
import 'package:gcc/Admin/adminhome.dart';
import 'package:gcc/Admin/adminorders.dart';
import 'package:gcc/Admin/adminprofile.dart';
import 'package:gcc/Admin/adminrevenue.dart';
import 'package:gcc/Screens/Loginpage.dart';
import 'package:gcc/Screens/signup.dart';
import 'package:gcc/provider/google_sign_in.dart';
import 'package:gcc/utils/checkuser.dart';
import 'package:gcc/utils/hexcolor.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showNotification(message);
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'bitebox_notifications_channel',
    'bitebox',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? 'Default Title',
    message.notification?.body ?? 'Default Body',
    platformChannelSpecifics,
    payload: 'item x',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    _showNotification(message);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GoogleSignInProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gcc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green[800]!,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: HexColor("#007E03"),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: CheckUser(),
      routes: {
        "/login": (context) => LoginPage(),
        "/signup": (context) => SignUp(),
        "/adminhome": (context) => AdminHome(initialSelectedIndex: 0),
        "/adminorders": (context) => AdminOrdersPage(),
        "/adminorderrequests": (context) => AdminOrderRequests(),
        "/adminrevenue": (context) => AdminRevenue(),
        "/adminprofile": (context) => AdminProfile(),
        // "/adminnotifications":(context)=>AdminNotifications(),
      },
    );
  }
}
