import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart'; // 로그아웃용

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("로그인된 사용자가 없습니다.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("내 프로필 🐾"),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("프로필 정보를 찾을 수 없습니다."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final dogName = data['name'] ?? '등록된 이름 없음';
          final breed = data['breed'] ?? '품종 정보 없음';
          final age = data['age'] ?? '나이 정보 없음';
          final size = data['size'] ?? '크기 정보 없음';
          final vaccinated = data['vaccinated'] == true ? "완료 ✅" : "미완료 ❌";
          final photoURL = data['imageURL'] ?? user.photoURL;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // 프로필 이미지
                CircleAvatar(
                  radius: 60,
                  backgroundImage: photoURL != null && photoURL.isNotEmpty
                      ? NetworkImage(photoURL)
                      : null,
                  backgroundColor: Colors.orange.shade100,
                  child: (photoURL == null || photoURL.isEmpty)
                      ? const Icon(Icons.pets, size: 50, color: Colors.white)
                      : null,
                ),

                const SizedBox(height: 25),

                Text(
                  dogName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "품종: $breed\n나이: $age살\n크기: $size\n예방접종: $vaccinated",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 40),

                // 이메일
                Text(
                  user.email ?? "이메일 없음",
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),

                const SizedBox(height: 40),

                // 로그아웃 버튼
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
                    await AuthService.signOut(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
