import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

class AuthService {
  // 구글 로그인
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _showErrorMessage(context, "사용자가 로그인을 취소했습니다.");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _showErrorMessage(context, "구글 인증 토큰을 가져올 수 없습니다.");
        return;
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
        _navigateToHomeScreen(context);
      }
    } catch (error) {
      _showErrorMessage(context, "구글 로그인에 실패했습니다.");
      print('🚨 Google login failed: $error');
    }
  }

  // 카카오 로그인
  static Future<void> signInWithKakao(BuildContext context) async {
    try {
      final isInstalled = await kakao.isKakaoTalkInstalled();

      if (isInstalled) {
        await kakao.UserApi.instance.loginWithKakaoTalk();
        print('✅ Kakao login successful (via KakaoTalk)');
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
        print('✅ Kakao login successful (via Web)');
      }

      final kakao.User user = await kakao.UserApi.instance.me();
      print('✅ Kakao user info: ${user.kakaoAccount?.profile?.nickname}');

      // TODO: 여기서 서버(Firebase Functions) 호출하여 Custom Token 생성 필요
      _navigateToHomeScreen(context);

    } catch (error) {
      _showErrorMessage(context, "카카오 로그인에 실패했습니다.");
      print('🚨 Kakao login failed: $error');
    }
  }

  // 로그아웃
  static Future<void> signOut(BuildContext context) async {
    try {
      await Future.wait([
        firebase_auth.FirebaseAuth.instance.signOut(),
        GoogleSignIn().signOut(),
        kakao.UserApi.instance.logout(),
      ]);
    } catch (error) {
      print("로그아웃 중 일부 서비스 오류: $error");
    }

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Firestore에 사용자 정보 저장
  static Future<void> _saveUserToFirestore(firebase_auth.User user) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    if (!(await userDoc.get()).exists) {
      await userDoc.set({
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 홈 화면으로 이동
  static void _navigateToHomeScreen(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  // 에러 메시지 표시
  static void _showErrorMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
