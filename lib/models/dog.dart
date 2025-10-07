import 'package:cloud_firestore/cloud_firestore.dart';
class Dog {
  final String id;
  final String name;
  final int age;
  final String breed;
  final String imageURL;

  Dog({
    required this.id,
    required this.name,
    required this.age,
    required this.breed,
    required this.imageURL,
  });

  /// Firestore 문서 → Dog 객체 변환
  factory Dog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Dog(
      id: doc.id, // 🔹 문서 ID 사용 가능
      name: data['name'] ?? '이름 없음',
      age: data['age'] ?? 0,
      breed: data['breed'] ?? '품종 없음',
      imageURL: data['imageURL'] ?? '', // 🔹 키 이름 주의 (imageUrl vs imageURL)
    );
  }

  /// JSON 변환 (필요 시)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'breed': breed,
      'imageURL': imageURL,
    };
  }
}
