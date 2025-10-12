import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/login_screen.dart';

class AuthService {
  /// ✅ 구글 로그인 (Firestore 문서 생성 X)
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _showErrorMessage(context, "사용자가 로그인을 취소했습니다.");
        return;
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _showErrorMessage(context, "구글 인증 토큰을 가져올 수 없습니다.");
        return;
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      final userCredential =
          await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        debugPrint("✅ Firebase Auth 로그인 완료: ${userCredential.user!.uid}");
        // Firestore 문서 자동생성 X
        // 이후 login_screen.dart 에서 Firestore 존재 여부 확인 후 분기
      }
    } catch (error) {
      _showErrorMessage(context, "구글 로그인에 실패했습니다.");
      debugPrint('🚨 Google login failed: $error');
    }
  }

  /// ✅ 로그아웃 (Firebase + Google)
  static Future<void> signOut(BuildContext context) async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (error) {
      debugPrint("로그아웃 중 오류: $error");
    }

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  /// (보류) Firestore에 사용자 정보 저장 함수
  /// → 로그인 직후 자동 호출 ❌
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

  /// 🔸 에러 메시지 표시
  static void _showErrorMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
