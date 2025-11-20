import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  /// 🔥 안읽은 메시지 개수 계산
  Future<int> getUnreadCount(String chatId, String myUid) async {
    final snap = await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("createdAt", descending: true)
        .get();

    int count = 0;

    for (var doc in snap.docs) {
      final data = doc.data();
      final readBy = List<String>.from(data["readBy"] ?? []);
      final senderId = data["senderId"];

      // 상대방이 보낸 + 내가 안읽은 경우만 카운트
      if (senderId != myUid && !readBy.contains(myUid)) {
        count++;
      }
    }

    return count;
  }

  /// 🔥 Timestamp → "오전 10:22" 형식 변환
  String formatTime(Timestamp? ts) {
    if (ts == null) return "";

    final date = ts.toDate();
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');

    final isPM = hour >= 12;
    final convertedHour = (hour % 12 == 0) ? 12 : hour % 12;

    return "${isPM ? '오후' : '오전'} $convertedHour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "메세지",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUser.uid)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "아직 매칭된 상대가 없습니다 🐾",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final data = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;

              final users = List<String>.from(data['users'] ?? []);
              final otherUserId =
                  users.firstWhere((id) => id != currentUser.uid);

              final lastMessage = data['lastMessage'] ?? "아직 대화가 없습니다 🐶";
              final lastTime = formatTime(data['updatedAt']);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      title: Text("불러오는 중..."),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

                  final dogName = userData['name'] ?? "강아지";
                  final photoUrl = userData['imageURL'] ?? '';

                  return FutureBuilder<int>(
                    future: getUnreadCount(chatId, currentUser.uid),
                    builder: (context, unreadSnapshot) {
                      int unreadCount = unreadSnapshot.data ?? 0;

                      return ListTile(
                        tileColor: Colors.white,
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.orangeAccent,
                          backgroundImage: (photoUrl.isNotEmpty)
                              ? NetworkImage(photoUrl)
                              : null,
                          child: (photoUrl.isEmpty)
                              ? const Icon(Icons.pets, color: Colors.white)
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                dogName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            /// 🔥 오른쪽에 "시간" 표시
                            Text(
                              lastTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        /// 🔥 마지막 메시지 + 안읽은 메시지 카운트
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),

                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(matchId: chatId),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
