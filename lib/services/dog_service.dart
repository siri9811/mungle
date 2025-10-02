import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dog.dart';

class DogService {
  static Future<List<Dog>> fetchDogs() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('dogs').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Dog.fromFirestore(data);
      }).toList();
    } catch (e) {
      print("Firestore fetch error: $e");
      return [];
    }
  }
}
