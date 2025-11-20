import 'package:cloud_firestore/cloud_firestore.dart';

class Dog {
  final String id;           // Firestore 문서 ID
  final String name;         // 이름
  final int age;             // 나이
  final String breed;        // 품종
  final String imageUrl;     // 프로필 이미지 URL
  final String? intro;       // 한줄소개 (optional)
  final String? size;        // 크기 (소형, 중형, 대형)
  final bool? vaccinated;    // 예방접종 여부
  final double lat;          // 위도
  final double lng;          // 경도
  final double? distanceKm;  // 사용자와의 거리 (선택적)

  Dog({
    required this.id,
    required this.name,
    required this.age,
    required this.breed,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    this.intro,
    this.size,
    this.vaccinated,
    this.distanceKm,
  });

  /// 🔹 Firestore → Dog 객체 변환
  factory Dog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Dog(
      id: doc.id,
      name: data['name'] ?? '이름 없음',
      age: data['age'] is int
          ? data['age']
          : int.tryParse(data['age']?.toString() ?? '0') ?? 0,
      breed: data['breed'] ?? '품종 없음',
      imageUrl: data['imageUrl'] ?? data['imageURL'] ?? '',
      intro: data['intro'] ?? '', // ✅ 한줄소개
      size: data['size'],         // ✅ 크기
      vaccinated: data['vaccinated'] ?? false, // ✅ 예방접종 여부
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      distanceKm: null,
    );
  }

  /// 🔹 Dog → Firestore Map 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'breed': breed,
      'intro': intro ?? '',
      'size': size,
      'vaccinated': vaccinated ?? false,
      'imageUrl': imageUrl,
      'lat': lat,
      'lng': lng,
    };
  }

  /// 🔹 거리값이 포함된 새로운 객체 반환
  Dog copyWith({double? distanceKm}) {
    return Dog(
      id: id,
      name: name,
      age: age,
      breed: breed,
      imageUrl: imageUrl,
      intro: intro,
      size: size,
      vaccinated: vaccinated,
      lat: lat,
      lng: lng,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
