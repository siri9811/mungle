class Dog {
  final String name;
  final int age;
  final String breed;
  final String imageUrl;

  Dog({
    required this.name,
    required this.age,
    required this.breed,
    required this.imageUrl,
  });

  // Firestore → Dog 변환
  factory Dog.fromFirestore(Map<String, dynamic> data) {
    return Dog(
      name: data['name'] ?? '이름 없음',
      age: data['age'] ?? 0,
      breed: data['breed'] ?? '품종 없음',
      imageUrl: data['imageURL'] ?? '',
    );
  }
}
