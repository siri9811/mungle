import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dog.dart';

class MatchService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// 거리 기반 추천 (현재 로그인한 강아지를 제외하고)
  static Future<List<Dog>> getNearbyDogs({
  required double userLat,
  required double userLng,
  double maxDistanceKm = 1000,
}) async {
  try {
    final snapshot = await _db.collection('users').get();
    final currentUid = _auth.currentUser?.uid;

    // Firestore에서 전체 Dog 불러오기
    final allDogs = snapshot.docs
        .map((d) => Dog.fromFirestore(d))
        .where((dog) => dog.id != currentUid) // 자기 자신 제외
        .toList();

    // 거리 계산 + Dog 객체에 distanceKm 추가
    List<Dog> withDistance = allDogs.map((dog) {
      final distance = _calculateDistance(userLat, userLng, dog.lat, dog.lng);
      return dog.copyWith(distanceKm: distance); // 거리 필드 추가
    }).toList();

    // 거리 제한 필터링
    List<Dog> nearby = withDistance
        .where((dog) => (dog.distanceKm ?? 99999) <= maxDistanceKm)
        .toList();

    // 가까운 순 정렬
    nearby.sort((a, b) =>
        (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));

    // 디버그 로그
    for (var d in nearby) {
      print("🐶 ${d.name}: ${d.distanceKm?.toStringAsFixed(2)} km");
    }

    return nearby;
  } catch (e) {
    print("🔥 MatchService.getNearbyDogs error: $e");
    return [];
  }
}
  /// 좋아요 / 싫어요 처리
  static Future<void> handleSwipe(Dog targetDog, bool liked) async {
    final user = _auth.currentUser!;
    final userRef = _db.collection('users').doc(user.uid);

    try {
      if (liked) {
        await userRef.set({
          'liked': FieldValue.arrayUnion([targetDog.id]),
        }, SetOptions(merge: true));

        final targetRef = _db.collection('users').doc(targetDog.id);
        final targetSnap = await targetRef.get();
        final targetLikes = List<String>.from(targetSnap.data()?['liked'] ?? []);

        if (targetLikes.contains(user.uid)) {
          await _createMatch(user.uid, targetDog.id, targetDog);
        }
      } else {
        await userRef.set({
          'disliked': FieldValue.arrayUnion([targetDog.id]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("MatchService.handleSwipe error: $e");
    }
  }

  /// 매칭 + 채팅방 생성
  static Future<void> _createMatch(String uid1, String uid2, Dog dog) async {
    try {
      final matchRef = _db.collection('matches').doc();

      await matchRef.set({
        'users': [uid1, uid2],
        'dogName': dog.name,
        'dogId': dog.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('chats').doc(matchRef.id).set({
        'users': [uid1, uid2],
        'lastMessage': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Match + Chat room created successfully");
    } catch (e) {
      print("MatchService._createMatch error: $e");
    }
  }

  /// 거리 계산
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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
