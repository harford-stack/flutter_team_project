import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getCategories() async {
    final snapshot = await _firestore.collection('ingredients').get();

    final categories = snapshot.docs
        .map((doc) => doc['category'] as String)
        .toSet()
        .toList();

    categories.remove('기타');
    categories.sort();

    return ['전체', ...categories, '기타'];
  }

  Future<List<String>> getIngredients(String category) async {
    Query query = _firestore.collection('ingredients');

    if (category != "전체") {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();

    final ingredients = snapshot.docs
        .map((doc) => doc['name'] as String)
        .toList();

    ingredients.sort();
    return ingredients;
  }
}