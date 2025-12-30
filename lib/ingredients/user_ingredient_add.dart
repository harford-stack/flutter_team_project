import 'package:flutter/material.dart';
import '../common/app_colors.dart';
import 'widget_search_bar.dart';
import 'widget_category_bar.dart';
import 'widget_ingredient_grid.dart';
import 'widget_ingredient_grid_with_category.dart';
import 'service_ingredientFirestore.dart';
import 'service_getCategoryIngre.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../recipes/ingreCheck_screen.dart';
import 'package:provider/provider.dart';
import '../providers/temp_ingre_provider.dart';

class IngredientWithCategory {
  final String name;
  final String category;

  IngredientWithCategory({
    required this.name,
    required this.category,
  });
}

class UserIngredientAdd extends StatefulWidget {
  const UserIngredientAdd({super.key});

  @override
  State<UserIngredientAdd> createState() => _UserIngredientAddState();
}

class _UserIngredientAddState extends State<UserIngredientAdd> {
  final IngredientService _service = IngredientService();
  final TextEditingController _searchController = TextEditingController();
  final GetCategoryIngre _getCategoryIngre = GetCategoryIngre();

  List<String> categoryTabs = [];
  List<Map<String, String>> ingredientList = [];
  List<Map<String, String>> filteredIngredients = [];

  int selectedCategoryIndex = 0;
  final Map<String, String> selectedIngredients = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkLoginStatus();
  }

  Future<void> _loadData() async {
    categoryTabs = await _service.getCategories();
    await _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final ingredients = await _getCategoryIngre.getIngredientsWithCategory(
        categoryTabs[selectedCategoryIndex]
    );

    setState(() {
      ingredientList = ingredients;
      filteredIngredients = ingredients;
    });
  }

  void _checkLoginStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("로그인 상태: ${user.displayName}");
      print(user.uid);
    } else {
      print("로그아웃 상태");
    }
  }

  void _filterIngredients(String query) {
    setState(() {
      filteredIngredients = query.isEmpty
          ? ingredientList
          : ingredientList
          .where((item) => item['name']!.contains(query))
          .toList();
    });
  }

  void _onCategoryChanged(int index) {
    setState(() {
      selectedCategoryIndex = index;
      _searchController.clear();
      _filterIngredients('');
    });
    _loadIngredients();
  }

  void _onIngredientTap(Map<String, String> item) {
    final name = item['name']!;
    final category = item['category']!; // 실제 카테고리 사용

    setState(() {
      if (selectedIngredients.containsKey(name)) {
        selectedIngredients.remove(name);
      } else {
        selectedIngredients[name] = category; // 실제 카테고리 저장
      }
    });
  }

  void _saveIngredients() async {
    User? user = FirebaseAuth.instance.currentUser;
    if(user == null) {
      // 로그인 후 이용하라는 알림 주기
      return;
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final DocumentReference userDocRef = firestore.collection('users').doc(user.uid);

    final ingredientsCollectionRef = userDocRef.collection('user-ingredients');
    final ingredientsSnapshot = await ingredientsCollectionRef.get();

    if (ingredientsSnapshot.docs.isNotEmpty) {
      print("이미 재료 정보가 저장되어 있습니다.");
      return;
    }

    for (var ingredient in selectedIngredients.entries) {
      final ingredientData = {
        'name' : ingredient.key,
        'category' : ingredient.value,
        'addedAt' : FieldValue.serverTimestamp(),
      };

      await ingredientsCollectionRef.add(ingredientData);
      print("재료 ${ingredient.key}가 추가되었습니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('재료 추가'),
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.textDark,
      ),
      body: Column(
        children: [
          IngredientSearchBar(
            controller: _searchController,
            onChanged: _filterIngredients,
          ),
          CategoryBar(
            categories: categoryTabs,
            selectedIndex: selectedCategoryIndex,
            onCategoryChanged: _onCategoryChanged,
          ),
          Expanded(
            child: IngredientGridWithCategory(
              ingredients: filteredIngredients.map((item) => item['name']!).toList(),
              selectedIngredients: selectedIngredients,
              onIngredientTap: (name) {
                // 이름으로 원본 데이터 찾기
                final item = filteredIngredients.firstWhere(
                      (item) => item['name'] == name,
                );
                _onIngredientTap(item);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: selectedIngredients.isNotEmpty
          ? ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          final selectedList = selectedIngredients.entries
              .map((entry) => {
              'name': entry.key,
              'category': entry.value,
            })
              .toList();

          print(selectedList);
          _saveIngredients();
        },
        child: const Text(
          "확인",
          style: TextStyle(color: AppColors.textWhite),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
