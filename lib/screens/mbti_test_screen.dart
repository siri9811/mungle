import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MbtiTestScreen extends StatefulWidget {
  const MbtiTestScreen({super.key});

  @override
  State<MbtiTestScreen> createState() => _MbtiTestScreenState();
}

class _MbtiTestScreenState extends State<MbtiTestScreen> {
  int currentIndex = 0;
  Map<String, int> scores = {
    "E": 0,
    "I": 0,
    "S": 0,
    "N": 0,
    "T": 0,
    "F": 0,
    "J": 0,
    "P": 0,
  };

  final List<Map<String, dynamic>> questions = [
    {
      "q": "산책을 나가면 강아지는 어떤가요?",
      "a1": {"text": "주변 강아지와 사람들에게 먼저 다가간다", "type": "E"},
      "a2": {"text": "조용히 주인 옆에서 걷는다", "type": "I"},
    },
    {
      "q": "강아지가 새로운 장난감을 받으면?",
      "a1": {"text": "바로 탐색하고 갖고 논다", "type": "S"},
      "a2": {"text": "조심스레 냄새 맡고 상황을 본다", "type": "N"},
    },
    {
      "q": "주인이 슬퍼보일때 강아지는?",
      "a1": {"text": "관심없이 혼자 놀고 있다", "type": "T"},
      "a2": {"text": "주인의 감정을 살핀다", "type": "F"},
    },
    {
      "q": "일상 루틴은 어떤가요?",
      "a1": {"text": "규칙적인 루틴을 선호한다", "type": "J"},
      "a2": {"text": "즉흥적으로 움직이는 편이다", "type": "P"},
    },
  ];

  void answer(String type) async {
    scores[type] = scores[type]! + 1;

    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      final result = _calculateMbti();
      await _saveResult(result);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MbtiResultScreen(result: result)),
      );
    }
  }

  String _calculateMbti() {
    String mbti = "";
    mbti += (scores["E"]! >= scores["I"]!) ? "E" : "I";
    mbti += (scores["S"]! >= scores["N"]!) ? "S" : "N";
    mbti += (scores["T"]! >= scores["F"]!) ? "T" : "F";
    mbti += (scores["J"]! >= scores["P"]!) ? "J" : "P";
    return mbti;
  }

  Future<void> _saveResult(String result) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "mbti": result,
      "mbtiUpdatedAt": FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("멍BTI 검사"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q["q"],
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // 답변 1
            ElevatedButton(
              onPressed: () => answer(q["a1"]["type"]),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                q["a1"]["text"],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),

            // 답변 2
            ElevatedButton(
              onPressed: () => answer(q["a2"]["type"]),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                q["a2"]["text"],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------
// 결과 화면
// ------------------------------

class MbtiResultScreen extends StatelessWidget {
  final String result;
  const MbtiResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final meanings = {
      "ESTJ": "리더견! 중심 잡는 타입 🐾",
      "INFP": "순둥순둥 감성견 💗",
      "ENFP": "발랄한 텐션왕 🐶🎉",
      "ISTJ": "진지한 규칙견 📘",
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("멍BTI 결과"),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              result,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              meanings[result] ?? "독특한 개성을 가진 멍이입니다!",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("돌아가기"),
            )
          ],
        ),
      ),
    );
  }
}
