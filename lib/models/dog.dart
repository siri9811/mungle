import 'package:cloud_firestore/cloud_firestore.dart';

class Dog {
  final String id;         // Firestore 문서 ID
  final String name;       // 이름
  final int age;           // 나이
  final String breed;      // 품종
  final String imageUrl;   // 이미지 URL
  final double lat;        // 위도
  final double lng;        // 경도
  final double? distanceKm; // 현재 사용자와의 거리 (선택적)

  Dog({
    required this.id,
    required this.name,
    required this.age,
    required this.breed,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    this.distanceKm, // 선택적 필드
  });

  /// Firestore → Dog 객체 변환
  factory Dog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Dog(
      id: doc.id, // = FirebaseAuth.currentUser.uid 와 동일
      name: data['name'] ?? '이름 없음',
      age: data['age'] is int
          ? data['age']
          : int.tryParse(data['age']?.toString() ?? '0') ?? 0,
      breed: data['breed'] ?? '품종 없음',
      imageUrl: data['imageURL'] ?? data['imageUrl'] ?? '',
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      distanceKm: null, // 처음에는 거리값 없음
    );
  }

  /// Dog → Firestore Map 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'breed': breed,
      'imageURL': imageUrl,
      'lat': lat,
      'lng': lng,
    };
  }

  /// 거리값이 포함된 새 객체를 반환하는 copyWith
  Dog copyWith({double? distanceKm}) {
    return Dog(
      id: id,
      name: name,
      age: age,
      breed: breed,
      imageUrl: imageUrl,
      lat: lat,
      lng: lng,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
