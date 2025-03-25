// import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
// import 'package:honeybee/view/intro/intro_page.dart';
import 'admin/hobby_add_page.dart';
import 'data/constant.dart';
import 'firebase_options.dart';

// 앱이 백그라운드에 있을 때 앱을 처리하는 함수
// 백그라운드에서 파이어베이스를 호출하여 알림을 보여 줌
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFlutterNotifications();
  showFlutterNotification(message);
  print('Handling a background message ${message.messageId}');
}

late AndroidNotificationChannel channel;
bool isFlutterLocalNotificationsInitialized = false;
// 플러터 알림 관련 설정하기
// 안드로이드는 채널을 등록해야 하므로 다음과 같은 설정이 필요함
Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'honey_bee_channel', // id
    'SNS 알림', // title
    description: '허니비 앱에서 사용하는 SNS 알림입니다.', // description
    importance: Importance.high,
  );
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
  // 알림을 보낼 때 어떻게 보낼지 정의하기(알림 창, 배지, 소리)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

// 알림을 직접 보이는 함수
// 서버에서 전달하는 데이터를 message 클래스에 담아서 각각 보여 줌
void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'noti_launch',
        ),
      ),
    );
  }
}

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupFlutterNotifications();
  runApp(const MyApp());
}

String? initialMessage;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.instance.getInitialMessage().then((value) {
      initialMessage = value?.data.toString();
    });
    // 앱이 실행될 때 메시지를 받으면 처리하는 콜백 함수
    FirebaseMessaging.onMessage.listen(showFlutterNotification);
    // 앱이 백그라운드에서 실행 중일 때 사용자가 알림을 탭하여 앱을 열 때 호출
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
    });
    return GetMaterialApp(
      title: Constant.APP_NAME,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const IntroPage(),
      home: HobbyAddPage(),
    );
  }
}
