import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../services/dog_service.dart';
import '../models/dog.dart';
import 'partner_profile_screen.dart'; // ✅ 추가

class ChatScreen extends StatefulWidget {
  final String matchId; // chats/{matchId}
  const ChatScreen({super.key, required this.matchId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  Dog? _otherDog;

  @override
  void initState() {
    super.initState();
    _loadOtherUserProfile();
  }

  /// 상대방 프로필 불러오기
  Future<void> _loadOtherUserProfile() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.matchId)
          .get();
      final users = List<String>.from(chatDoc['users']);
      final otherUid = users.firstWhere((id) => id != _currentUser!.uid);
      final dog = await DogService.getDogById(otherUid);
      setState(() => _otherDog = dog);
    } catch (e) {
      debugPrint("🔥 프로필 로드 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ 흰색 통일
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: GestureDetector(
          onTap: () {
            if (_otherDog != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PartnerProfileScreen(dog: _otherDog!),
                ),
              );
            }
          },
          child: Row(
            children: [
              if (_otherDog?.imageUrl != null && _otherDog!.imageUrl.isNotEmpty)
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(_otherDog!.imageUrl),
                )
              else
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.pets, color: Colors.white),
                ),
              const SizedBox(width: 10),
              Text(
                _otherDog?.name ?? "채팅",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: ChatService.getMessages(widget.matchId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "아직 메시지가 없습니다 🐾",
                      style: TextStyle(color: Colors.black87),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data =
                        messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUser?.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: 8.0, bottom: 2),
                              child: _otherDog?.imageUrl != null &&
                                      _otherDog!.imageUrl.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 18,
                                      backgroundImage:
                                          NetworkImage(_otherDog!.imageUrl),
                                    )
                                  : const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.orange,
                                      child:
                                          Icon(Icons.pets, color: Colors.white),
                                    ),
                            ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.orange.shade200
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(
                                      isMe ? 12 : 0),
                                  bottomRight: Radius.circular(
                                      isMe ? 0 : 12),
                                ),
                              ),
                              child: Text(
                                data['text'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 💬 메시지 입력 영역
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "메시지를 입력하세요...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.orange),
                  onPressed: () async {
                    if (_controller.text.trim().isEmpty) return;

                    await ChatService.sendMessage(
                      widget.matchId,
                      _controller.text.trim(),
                    );

                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
