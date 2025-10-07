import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("내 프로필 🐾"),
        centerTitle: true,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text("로그인된 사용자가 없습니다."))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // 프로필 이미지 (구글 로그인 시 사진 표시)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    backgroundColor: Colors.orange.shade100,
                    child: user.photoURL == null
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // ✅ 이름
                  Text(
                    user.displayName ?? '이름 없음',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ 이메일
                  Text(
                    user.email ?? '이메일 없음',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ✅ 로그아웃 버튼
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "로그아웃",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        // 로그인 화면으로 돌아가기
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/', (Route<dynamic> route) => false);
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
