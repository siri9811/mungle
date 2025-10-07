import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("매칭 & 채팅 💬"),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .where('users', arrayContains: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data!.docs;

          if (matches.isEmpty) {
            return const Center(
              child: Text(
                "아직 매칭된 상대가 없습니다 🐾",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final data = match.data() as Map<String, dynamic>;

              final dogName = data['dogName'] ?? '강아지';
              final lastMessage = data['lastMessage'] ?? '아직 대화가 없습니다 🐶';

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.pets, color: Colors.white),
                ),
                title: Text(dogName, style: const TextStyle(fontSize: 16)),
                subtitle: Text(
                  lastMessage,
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(matchId: match.id),
                    ),
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
