import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 이미 로그인 되어있는지 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _navigateBasedOnUser(user);
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      final user = authProvider.user;
      if (user != null) {
        await _navigateBasedOnUser(user);
      }
    } else if (authProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _navigateBasedOnUser(firebase_auth.User user) async {
    try {
      // Firestore에서 유저 문서 확인
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      if (mounted) {
        if (userDoc.exists && data != null && data['name'] != null) {
          // 기존 유저 → 메인 화면 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else {
          // 신규 유저 → 회원가입 화면 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SignupScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("🔥 유저 정보 확인 중 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppConstants.loginFailed}$e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 300.0;
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

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
              isLoading
                  ? const SizedBox(
                      height: 110,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          width: buttonWidth,
                          child: InkWell(
                            onTap: _handleGoogleLogin,
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
