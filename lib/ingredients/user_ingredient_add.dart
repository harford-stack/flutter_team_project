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
  final ScrollController _scrollController = ScrollController();

  List<String> categoryTabs = [];
  List<Map<String, String>> ingredientList = [];
  List<Map<String, String>> filteredIngredients = [];

  int selectedCategoryIndex = 0;
  final Map<String, String> selectedIngredients = {};

  Set<String> disabledIngredients = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkLoginStatus();
    _getUserIngredients();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    categoryTabs = await _service.getCategories();
    await _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    categoryTabs = await _service.getCategories();
    final ingredients = await _getCategoryIngre.getIngredientsWithCategory(
        categoryTabs[selectedCategoryIndex]
    );

    // 3. Firestore에서 사용자 재료 목록 불러오기
    List<String> userIngredients = await _getUserIngredients();
    final userIngredientsSet = userIngredients.toSet();

    // 이미 저장된 재료들을 먼저 배치하고, 나머지 재료들을 뒤에 배치
    final sortedIngredients = <Map<String, String>>[];
    final otherIngredients = <Map<String, String>>[];

    for (var ingredient in ingredients) {
      if (userIngredientsSet.contains(ingredient['name'])) {
        sortedIngredients.add(ingredient);
      } else {
        otherIngredients.add(ingredient);
      }
    }

    // 이미 저장된 재료들 + 나머지 재료들 순서로 합치기
    final finalIngredients = [...sortedIngredients, ...otherIngredients];

    setState(() {
      ingredientList = finalIngredients;
      filteredIngredients = finalIngredients;

      disabledIngredients = userIngredientsSet;
    });
  }

  void _checkLoginStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("로그인 상태");
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
    // 스크롤을 맨 위로 초기화
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    _loadIngredients();
  }

  void _onIngredientTap(Map<String, String> item) {
    final name = item['name']!;

    // 이미 추가된 재료는 클릭 불가능
    if (disabledIngredients.contains(name)) {
      return; // 아무 작업도 하지 않음
    }

    setState(() {
      if (selectedIngredients.containsKey(name)) {
        selectedIngredients.remove(name);
      } else {
        selectedIngredients[name] = item['category']!;
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

    List<String> existingIngredients = await _getUserIngredients();

    // final ingredientsSnapshot = await ingredientsCollectionRef.get();
    // if (ingredientsSnapshot.docs.isNotEmpty) {
    //   print("이미 재료 정보가 저장되어 있습니다.");
    //   return;
    // }

    for (var ingredient in selectedIngredients.entries) {
      if (existingIngredients.contains(ingredient.key)) {
        print("재료 ${ingredient.key}는 이미 추가되어 있습니다. 건너뜁니다.");
        continue;
      }

      final ingredientData = {
        'name' : ingredient.key,
        'category' : ingredient.value,
        'addedAt' : FieldValue.serverTimestamp(),
      };

      await ingredientsCollectionRef.add(ingredientData);
      print("재료 ${ingredient.key}가 추가되었습니다.");
    }

    Navigator.pop(context);
  }

  Future<List<String>> _getUserIngredients() async {
    User? user = FirebaseAuth.instance.currentUser;
    if ( user == null) {
      return [];
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference userDocRef = firestore.collection('users').doc(user.uid);
    final ingredientsCollectionRef = userDocRef.collection('user-ingredients');

    final ingredientsSnapshot = await ingredientsCollectionRef.get();
    List<String> userIngredients = [];

    for ( var doc in ingredientsSnapshot.docs) {
      userIngredients.add(doc['name']);
    }

    print(userIngredients);

    return userIngredients;
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
      body: SafeArea(
        child: Column(
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
                disabledIngredients: disabledIngredients,
                scrollController: _scrollController,
                onIngredientTap: (name) {
                  // 이미 선택된 재료는 클릭할 수 없도록 처리
                  if (selectedIngredients.containsKey(name)) return;

                  final item = filteredIngredients.firstWhere((item) => item['name'] == name);
                  _onIngredientTap(item);
                },
              ),
            ),
          ],
        ),
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
