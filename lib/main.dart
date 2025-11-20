import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mungle/services/push_service.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase 초기화 (한 번만)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PushService.initFCM();
  // 🚫 개발 중 로그인 초기화 (테스트용, 실제 서비스 시 삭제)
  await firebase_auth.FirebaseAuth.instance.signOut();
  await GoogleSignIn().signOut();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mungle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<firebase_auth.User?>(
        stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Firebase 연결 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // ✅ 로그인 되어 있든 안 되어 있든 — 항상 LoginScreen으로 진입
          // (LoginScreen 내부에서 Firestore 존재 여부 확인 후 Main 또는 Signup으로 이동)
          return const LoginScreen();
        },
      ),
    );
  }
}
