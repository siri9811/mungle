import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dog.dart';

class MatchService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// 사용자가 강아지를 스와이프할 때 호출
  static Future<void> handleSwipe(Dog dog, bool liked) async {
    final user = _auth.currentUser!;
    final userRef = _db.collection('users').doc(user.uid);

    try {
      if (liked) {
        // 좋아요 추가 (필드 없으면 새로 생성)
        await userRef.set({
          'liked': FieldValue.arrayUnion([dog.id]),
        }, SetOptions(merge: true));

        // 상대방(ownerId)이 나를 이미 좋아했는지 확인
        if (dog is! Dog || dog.id.isEmpty) return;

        final ownerId = (dog as dynamic).ownerId ?? '';
        if (ownerId.isEmpty) return; // ownerId가 없으면 매칭 확인 불가

        final ownerRef = _db.collection('users').doc(ownerId);
        final ownerSnap = await ownerRef.get();

        final likedList = List<String>.from(ownerSnap.data()?['liked'] ?? []);

        if (likedList.contains(user.uid)) {
          await _createMatch(user.uid, ownerId, dog);
        }
      } else {
        // 싫어요 추가
        await userRef.set({
          'disliked': FieldValue.arrayUnion([dog.id]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("🔥 MatchService.handleSwipe error: $e");
    }
  }

  /// 매칭 생성 시 호출
  static Future<void> _createMatch(String uid1, String uid2, Dog dog) async {
    try {
      final matchRef = _db.collection('matches').doc();

      await matchRef.set({
        'users': [uid1, uid2],
        'dogName': dog.name,
        'dogId': dog.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 채팅방도 함께 생성
      await _db.collection('chats').doc(matchRef.id).set({
        'users': [uid1, uid2],
        'lastMessage': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("🔥 MatchService._createMatch error: $e");
    }
  }
}
