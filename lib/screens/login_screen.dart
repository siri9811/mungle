import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signIn(Future<void> Function(BuildContext) signInMethod) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await signInMethod(context);

      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("로그인 정보가 없습니다.");

      // Firestore에서 유저 문서 확인
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      if (userDoc.exists && data != null && data['name'] != null) {
        // 기존 유저 → 메인 화면 이동
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        // 신규 유저 → 회원가입 화면 이동
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SignupScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("🔥 로그인 중 오류: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("로그인 실패: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 300.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔹 로고 + 텍스트 (틴더 스타일)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/mungle_logo.png',
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Mungle',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 100),

              // 🔹 로딩 중일 때 로딩 스피너 표시
              _isLoading
                  ? const SizedBox(
                      height: 110,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          width: buttonWidth,
                          child: InkWell(
                            onTap: () => _signIn(AuthService.signInWithGoogle),
                            child: Image.asset(
                              'assets/images/google_login_button.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
