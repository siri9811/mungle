import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class AuthService {
  /// ✅ 구글 로그인 (Firestore 문서 생성 X)
  /// 성공 시 UserCredential 반환, 실패/취소 시 null 또는 에러 throw
  static Future<firebase_auth.UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // 사용자가 취소함
        return null;
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception(AppConstants.googleTokenError);
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      final userCredential =
          await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        debugPrint("✅ Firebase Auth 로그인 완료: ${userCredential.user!.uid}");
      }
      
      return userCredential;

    } catch (error) {
      debugPrint('🚨 Google login failed: $error');
      throw Exception(AppConstants.googleLoginError);
    }
  }

  /// ✅ 로그아웃 (Firebase + Google)
  static Future<void> signOut() async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (error) {
      debugPrint("로그아웃 중 오류: $error");
    }
  }

  /// (보류) Firestore에 사용자 정보 저장 함수
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
}
