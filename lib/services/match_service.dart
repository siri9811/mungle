import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dog.dart';
import 'dog_service.dart';

class MatchService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// ✅ 거리 기반 추천 (좋아요/싫어요/매칭 제외)
  static Future<List<Dog>> getNearbyDogs({
    required double userLat,
    required double userLng,
    double maxDistanceKm = 1000,
  }) async {
    try {
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null) return [];

      // 현재 유저 데이터 불러오기
      final currentData = await DogService.getCurrentUserData(currentUid);
      final liked = List<String>.from(currentData?['liked'] ?? []);
      final disliked = List<String>.from(currentData?['disliked'] ?? []);
      final matched = List<String>.from(currentData?['matched'] ?? []);
      final excluded = {...liked, ...disliked, ...matched, currentUid};

      // 모든 강아지 중 제외된 id 빼고 필터링
      final allDogs = await DogService.getAllDogs();
      final filtered = allDogs.where((d) => !excluded.contains(d.id)).toList();

      // 거리순 정렬
      final nearby = filtered
          .map((dog) {
            final distance = DogService.calculateDistance(
                userLat, userLng, dog.lat, dog.lng);
            return dog.copyWith(distanceKm: distance);
          })
          .where((dog) => (dog.distanceKm ?? 9999) <= maxDistanceKm)
          .toList()
        ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));

      return nearby;
    } catch (e) {
      print("🔥 MatchService.getNearbyDogs error: $e");
      return [];
    }
  }

  /// ✅ 좋아요 / 싫어요 (한쪽만 눌러도 즉시 매칭)
  static Future<void> handleSwipe(Dog targetDog, bool liked) async {
    final user = _auth.currentUser!;
    final userRef = _db.collection('users').doc(user.uid);
    final targetRef = _db.collection('users').doc(targetDog.id);

    try {
      if (liked) {
        // 👍 좋아요 등록
        await userRef.set({
          'liked': FieldValue.arrayUnion([targetDog.id]),
        }, SetOptions(merge: true));

        // 💬 바로 매칭 생성
        await _createMatch(user.uid, targetDog.id);

        // 🔄 서로 추천 목록에서 제거하고 matched 등록
        await userRef.update({
          'liked': FieldValue.arrayRemove([targetDog.id]),
          'matched': FieldValue.arrayUnion([targetDog.id]),
        });
        await targetRef.set({
          'matched': FieldValue.arrayUnion([user.uid]),
        }, SetOptions(merge: true));
      } else {
        // ❌ 싫어요
        await userRef.set({
          'disliked': FieldValue.arrayUnion([targetDog.id]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("🔥 MatchService.handleSwipe error: $e");
    }
  }

  /// ✅ 매칭 + 채팅 + 알림 생성 (즉시)
  static Future<void> _createMatch(String uid1, String uid2) async {
    try {
      // 이미 존재하는 채팅이 있는지 확인
      final existing = await _db
          .collection('chats')
          .where('users', arrayContains: uid1)
          .get();

      final alreadyExists = existing.docs.any((doc) {
        final users = List<String>.from(doc['users'] ?? []);
        return users.contains(uid2);
      });
      if (alreadyExists) return;

      // 🗨️ 채팅 생성
      final chatRef = _db.collection('chats').doc();
      await chatRef.set({
        'users': [uid1, uid2],
        'lastMessage': "매칭이 성사되었습니다! 🐾",
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 🔔 알림 생성 (양쪽 다)
      final now = FieldValue.serverTimestamp();
      final batch = _db.batch();

      final notif1 = _db
          .collection('users')
          .doc(uid1)
          .collection('notifications')
          .doc();
      final notif2 = _db
          .collection('users')
          .doc(uid2)
          .collection('notifications')
          .doc();

      batch.set(notif1, {
        'type': 'match',
        'withUserId': uid2,
        'chatId': chatRef.id,
        'message': '매칭이 성사되었어요! 🐾',
        'createdAt': now,
        'read': false,
      });
      batch.set(notif2, {
        'type': 'match',
        'withUserId': uid1,
        'chatId': chatRef.id,
        'message': '매칭이 성사되었어요! 🐾',
        'createdAt': now,
        'read': false,
      });

      await batch.commit();
      print("💬 즉시 매칭 생성 완료 ($uid1 ↔ $uid2)");
    } catch (e) {
      print("🔥 MatchService._createMatch error: $e");
    }
  }
}
