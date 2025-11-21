import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:mungle/services/push_service.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase 초기화 (한 번만)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await PushService.initFCM(); // This line was removed as per the instruction's target code.
  // 🚫 개발 중 로그인 초기화 (테스트용, 실제 서비스 시 삭제)
  if (kDebugMode) {
    await firebase_auth.FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
      home: const LoginScreen(), // LoginScreen 내부에서 상태 체크 후 이동
    );
  }
}
