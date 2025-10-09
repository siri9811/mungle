import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Stream<QuerySnapshot> getMessages(String matchId) {
    return _db
        .collection('chats')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> sendMessage(String matchId, String text) async {
    final user = _auth.currentUser!;
    final msgRef = _db.collection('chats').doc(matchId).collection('messages').doc();

    await msgRef.set({
      'senderId': user.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db.collection('chats').doc(matchId).update({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
