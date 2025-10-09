import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dog.dart';

class DogService {
  static Future<List<Dog>> fetchDogs() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('dogs').get();

      // 각 문서를 Dog 객체로 변환
      return snapshot.docs.map((doc) => Dog.fromFirestore(doc)).toList();
    } catch (e) {
      print("🔥 Firestore fetch error: $e");
      return [];
    }
  }
}
