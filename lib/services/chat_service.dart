import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// 실시간 메시지 스트림
  static Stream<QuerySnapshot> getMessages(String matchId) {
    return _db
        .collection('chats')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 메시지 전송 (+ readBy 필드 포함)
  static Future<void> sendMessage(String matchId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final msgRef = _db
          .collection('chats')
          .doc(matchId)
          .collection('messages')
          .doc();

      await msgRef.set({
        'senderId': user.uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),

        // 읽음 처리: 보낸 사람만 기본 읽음 상태
        'readBy': [user.uid],
      });

      // 상위 chats 문서 갱신
      await _db.collection('chats').doc(matchId).update({
        'lastMessage': text,
        'lastSenderId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print("💬 메시지 전송 성공 (${user.uid}): $text");
    } catch (e) {
      print("🔥 ChatService.sendMessage error: $e");
    }
  }
}
