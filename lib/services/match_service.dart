import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dog.dart';
import 'dog_service.dart';

class MatchService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// 거리 기반 추천 (좋아요/싫어요 제외)
  static Future<List<Dog>> getNearbyDogs({
    required double userLat,
    required double userLng,
    double maxDistanceKm = 1000,
  }) async {
    try {
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null) return [];

      final currentData = await DogService.getCurrentUserData(currentUid);
      final liked = List<String>.from(currentData?['liked'] ?? []);
      final disliked = List<String>.from(currentData?['disliked'] ?? []);
      final excluded = {...liked, ...disliked, currentUid};

      final allDogs = await DogService.getAllDogs();
      final filtered = allDogs.where((d) => !excluded.contains(d.id)).toList();

      final nearby = filtered.map((dog) {
        final distance = DogService.calculateDistance(userLat, userLng, dog.lat, dog.lng);
        return dog.copyWith(distanceKm: distance);
      }).where((dog) => (dog.distanceKm ?? 9999) <= maxDistanceKm)
        .toList()
        ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));

      return nearby;
    } catch (e) {
      print("🔥 MatchService.getNearbyDogs error: $e");
      return [];
    }
  }

  /// 좋아요/싫어요
  static Future<void> handleSwipe(Dog targetDog, bool liked) async {
    final user = _auth.currentUser!;
    final userRef = _db.collection('users').doc(user.uid);
    final targetRef = _db.collection('users').doc(targetDog.id);

    try {
      if (liked) {
        await userRef.set({
          'liked': FieldValue.arrayUnion([targetDog.id]),
        }, SetOptions(merge: true));

        final targetSnap = await targetRef.get();
        final targetLikes = List<String>.from(targetSnap.data()?['liked'] ?? []);

        if (targetLikes.contains(user.uid)) {
          await _createMatch(user.uid, targetDog.id);
        }
      } else {
        await userRef.set({
          'disliked': FieldValue.arrayUnion([targetDog.id]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("🔥 MatchService.handleSwipe error: $e");
    }
  }

  /// 매칭 + 채팅 생성
  static Future<void> _createMatch(String uid1, String uid2) async {
    try {
      final chatRef = _db.collection('chats').doc();
      await chatRef.set({
        'users': [uid1, uid2],
        'lastMessage': "매칭이 성사되었습니다! 🐾",
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("🔥 MatchService._createMatch error: $e");
    }
  }
}
