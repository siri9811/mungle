import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/dog.dart';

class UserProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> registerDogProfile({
    required String name,
    required int age,
    required String breed,
    required String intro,
    required String size,
    required bool vaccinated,
    required XFile image,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = "로그인 정보가 없습니다.";
      _setLoading(false);
      return false;
    }

    try {
      // 1. 이미지 업로드
      final file = File(image.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles/${user.uid}/profile.jpg');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      // 2. Dog 모델 생성
      final dog = Dog(
        id: user.uid,
        name: name,
        age: age,
        breed: breed,
        imageUrl: imageUrl,
        lat: 0,
        lng: 0,
      );

      // 3. Firestore 저장
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        ...dog.toMap(),
        'intro': intro,
        'size': size,
        'vaccinated': vaccinated,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "등록 중 오류 발생: $e";
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
