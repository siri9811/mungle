import 'package:flutter/material.dart';
import '../models/dog.dart';

class DogCard extends StatelessWidget {
  final Dog dog;
  const DogCard({super.key, required this.dog});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Container(
        width: screenWidth * 0.85,
        height: screenHeight * 0.65, // 버튼 제외, 카드만 보여줌
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // 🐶 이미지
            Expanded(
              flex: 7,
              child: dog.imageUrl.isNotEmpty
                  ? Image.network(
                      dog.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.pets, size: 80, color: Colors.grey),
                    )
                  : const Icon(Icons.pets, size: 100, color: Colors.grey),
            ),

            // 📋 정보 영역
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF8F0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dog.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${dog.age}살 / ${dog.breed}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  if (dog.distanceKm != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            "${dog.distanceKm!.toStringAsFixed(1)} km 거리",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
