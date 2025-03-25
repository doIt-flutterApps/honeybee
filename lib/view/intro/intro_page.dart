import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:honeybee/data/constant.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/user.dart';
import '../auth/auth_page.dart';
import '../hobby/hobby_selection_page.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _IntroPage();
  }
}

class _IntroPage extends State<IntroPage> {
  late HoneyBeeUser user;

  Future<bool> _notiPermissionCheck() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _loginCheck() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    String? id = preferences.getString("id");
    String? pw = preferences.getString("pw");
    String? hobby = preferences.getString("hobby");
    if (id != null && pw != null) {
      final FirebaseAuth auth = FirebaseAuth.instance;
      try {
        await auth.signInWithEmailAndPassword(email: id, password: pw);
        user = HoneyBeeUser(
          email: auth.currentUser!.email!,
          uid: auth.currentUser!.uid,
        );
        user.hobby = hobby;
        Get.put(user);
        return true;
      } on FirebaseAuthException catch (e) {
        return false;
      }
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
              return const Center(child: CircularProgressIndicator());
            case ConnectionState.done:
              if (snapshot.data != null) {
                // if (snapshot.data!) {
                  _notiPermissionCheck().then((value) {
                    _loginCheck().then((value) {
                      if (value == true) {
                        Future.delayed(const Duration(seconds: 2), () {
                          Get.snackbar(Constant.APP_NAME, '로그인했습니다.');
                          if (user.hobby != null) {
                            // 메인 페이지로 이동하기
                          } else {
                            // 취미 선택 페이지로 이동하기
                            Get.off(HobbySelectionPage());
                          }
                        });
                      } else {
                        Future.delayed(const Duration(seconds: 2), () {
                          // 회원 가입 페이지로 이동하기
                          Get.off(const AuthPage());
                        });
                      }
                    });
                  });
                  return Container(
                    color: Colors.greenAccent,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            Constant.APP_NAME,
                            style: TextStyle(
                              fontSize: 50,
                              fontFamily: 'clover',
                            ),
                          ),
                          SizedBox(height: 20),
                          Lottie.asset('res/animation/honeybee.json'),
                        ],
                      ),
                    ),
                  );
                // } else {
                //   return AlertDialog(
                //     title: Text(Constant.APP_NAME),
                //     content: Text(
                //       '인터넷에 연결되지 않아 '
                //       '허니비 SNS를 사용할 수 없습니다.',
                //     ),
                //     actions: [],
                //   );
                // }
              } else {
                return const Center(child: Text('데이터가 없습니다.'));
              }
            case ConnectionState.waiting:
              return const Center(child: CircularProgressIndicator());
            case ConnectionState.none:
              return const Center(child: Text('데이터가 없습니다.'));
          }
        },
        future: connectCheck(),
      ),
    );
  }

  Future<bool> connectCheck() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }
}
