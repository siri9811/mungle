import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  const ChatScreen({super.key, required this.matchId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("채팅")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: ChatService.getMessages(widget.matchId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final messages = snapshot.data!.docs;
                return ListView(
                  reverse: true,
                  children: messages.map((msg) {
                    final data = msg.data() as Map<String, dynamic>;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(data['text']),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: "메시지를 입력하세요..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      ChatService.sendMessage(widget.matchId, _controller.text);
                      _controller.clear();
                    }
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
