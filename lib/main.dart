import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ★★★ 'firebase_auth' 라는 별명을 붙여줍니다. ★★★
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ★★★ 여기에 발급받은 카카오 네이티브 앱 키를 꼭 넣어주세요 ★★★
  KakaoSdk.init(nativeAppKey: '##');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: StreamBuilder<firebase_auth.User?>( // ★★★ firebase_auth.User로 명확하게 지정 ★★★
        stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

