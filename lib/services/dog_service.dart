import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/dog.dart';

class DogService {
  static final _db = FirebaseFirestore.instance;

  /// 전체 유저(강아지) 불러오기
  static Future<List<Dog>> getAllDogs() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs.map((doc) => Dog.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("🔥 DogService.getAllDogs error: $e");
      return [];
    }
  }

  /// 특정 강아지 정보
  static Future<Dog?> getDogById(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? Dog.fromFirestore(doc) : null;
    } catch (e) {
      debugPrint("🔥 DogService.getDogById error: $e");
      return null;
    }
  }

  /// 내 유저 데이터 불러오기 (좋아요, 위치 등)
  static Future<Map<String, dynamic>?> getCurrentUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint("🔥 DogService.getCurrentUserData error: $e");
      return null;
    }
  }

  /// 거리 계산 (Haversine)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * pi / 180;
}
