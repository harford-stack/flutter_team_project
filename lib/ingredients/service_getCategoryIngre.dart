import 'package:cloud_firestore/cloud_firestore.dart';

class GetCategoryIngre {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, String>>> getIngredientsWithCategory(String category) async {
    try {
      Query query = _firestore.collection('ingredients');

      if (category != '전체') {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          'name': doc['name'] as String,
          'category': doc['category'] as String, // 실제 카테고리 정보
        };
      }).toList();
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}