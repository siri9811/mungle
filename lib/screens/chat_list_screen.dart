import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  // 🔥 채팅방 나가기
  Future<void> leaveChat(String chatId, String myUid) async {
    await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .update({
      "users": FieldValue.arrayRemove([myUid]),
    });
  }

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
      if (data["senderId"] != myUid && !readBy.contains(myUid)) {
        count++;
      }
    }
    return count;
  }

  String formatTime(Timestamp? ts) {
    if (ts == null) return "";
    final date = ts.toDate();
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final isPM = hour >= 12;
    final converted = (hour % 12 == 0) ? 12 : hour % 12;
    return "${isPM ? "오후" : "오전"} $converted:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("메세지",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("users", arrayContains: currentUser.uid)
            .orderBy("updatedAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;
              final chatId = chat.id;
              final users = List<String>.from(data["users"]);
              final otherUid =
                  users.firstWhere((uid) => uid != currentUser.uid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(otherUid)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final dogName = userData["name"] ?? "강아지";
                  final photoUrl = userData["imageURL"] ?? "";
                  final lastMessage = data["lastMessage"] ?? "";
                  final lastTime = formatTime(data["updatedAt"]);

                  return FutureBuilder<int>(
                    future: getUnreadCount(chatId, currentUser.uid),
                    builder: (context, unreadSnap) {
                      final unread = unreadSnap.data ?? 0;

                      return Slidable(
                        key: Key(chatId),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(), // 살짝만 밀어도 등장
                          extentRatio: 0.25, // 버튼 크기 작게
                          children: [
                            SlidableAction(
                              onPressed: (_) async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)),
                                    title: const Text("채팅방 나가기"),
                                    content: const Text(
                                        "정말로 이 채팅방을 나가시겠습니까?\n대화 기록은 상대방에게 남아있습니다."),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("취소")),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("나가기",
                                              style: TextStyle(
                                                  color: Colors.red))),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await leaveChat(chatId, currentUser.uid);
                                }
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.exit_to_app,
                              label: "나가기",
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.orangeAccent,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
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
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(lastTime,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(color: Colors.grey),
                                ),
                              ),
                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unread.toString(),
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
                        ),
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
