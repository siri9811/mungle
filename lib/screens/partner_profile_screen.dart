import 'package:flutter/material.dart';
import '../models/dog.dart';

class PartnerProfileScreen extends StatelessWidget {
  final Dog dog;

  const PartnerProfileScreen({super.key, required this.dog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🐶 프로필 이미지
            CircleAvatar(
              radius: 80,
              backgroundImage: dog.imageUrl.isNotEmpty
                  ? NetworkImage(dog.imageUrl)
                  : const AssetImage('assets/default_dog.png')
                      as ImageProvider,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 20),

            // 이름
            Text(
              dog.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            // 나이 + 품종
            const SizedBox(height: 6),
            Text(
              "${dog.age}살  |  ${dog.breed}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            // 거리 (있을 경우)
            if (dog.distanceKm != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "📍 ${dog.distanceKm!.toStringAsFixed(1)} km 거리",
                  style: const TextStyle(color: Colors.black54),
                ),
              ),

            const SizedBox(height: 24),

            // 구분선
            Divider(color: Colors.grey[300], thickness: 1),

            const SizedBox(height: 16),

            // ✅ 한줄소개
            if (dog.intro != null && dog.intro!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🐾 한줄소개",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dog.intro!,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // ✅ 크기 + 예방접종 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoChip(
                    icon: Icons.pets,
                    label: dog.size ?? '정보 없음',
                    color: Colors.orangeAccent),
                _buildInfoChip(
                  icon: Icons.vaccines,
                  label: dog.vaccinated == true ? '접종 완료' : '미접종',
                  color: dog.vaccinated == true
                      ? Colors.green
                      : Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 닫기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
                label: const Text(
                  "돌아가기",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 정보 칩 (크기, 예방접종 등)
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      backgroundColor: color,
      label: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}
