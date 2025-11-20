import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PushService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> initFCM() async {
    // 권한 요청
    await _messaging.requestPermission();

    // FCM 토큰 가져오기
    final token = await _messaging.getToken();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({"fcmToken": token});
    }

    // 토큰이 갱신될 때마다 Firestore 업데이트
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (user != null) {
        FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"fcmToken": newToken});
      }
    });
  }
}
