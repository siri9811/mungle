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
        width: screenWidth * 0.85, // 카드 가로 폭
        height: screenHeight * 0.65, // 카드 높이 (적당한 비율)
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
            // 강아지 이미지 영역
            SizedBox(
              height: screenHeight * 0.45,
              width: double.infinity,
              child: dog.imageURL.isNotEmpty
                  ? Image.network(
                      dog.imageURL,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.pets, size: 80, color: Colors.grey),
                    )
                  : const Icon(Icons.pets, size: 100, color: Colors.grey),
            ),

            // 정보 영역
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
