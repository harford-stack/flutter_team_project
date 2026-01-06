import 'package:flutter/material.dart';
import '../common/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widget_category_bar.dart';
import 'widget_search_bar.dart';

class UserIngredientRemove extends StatefulWidget {
  const UserIngredientRemove({super.key});

  @override
  State<UserIngredientRemove> createState() => _UserIngredientRemoveState();
}

class _UserIngredientRemoveState extends State<UserIngredientRemove> {
  User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, String>> userIngredients = [];
  List<String> categories = [];
  List<String> ingredientList = [];
  List<String> filteredIngredients = [];
  final TextEditingController _searchController = TextEditingController();

  int selectedCategoryIndex = 0;

  List<Map<String, String>> selectedIngredients = [];

  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;

  void _scrollListener() {
    if (_scrollController.offset >= 50) {
      if (!_showScrollToTopButton) {
        setState(() {
          _showScrollToTopButton = true;
        });
      }
    } else {
      if (_showScrollToTopButton) {
        setState(() {
          _showScrollToTopButton = false;
        });
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _checkLoginStatus() {
    if (user != null) {
      print("로그인 상태");
    } else {
      print("로그아웃 상태");
    }
  }

  Future<void> _removeSelectIngredients() async {
    if(user == null){
      return;
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference userDocRef = firestore.collection('users').doc(user!.uid);
    final ingredientsCollectionRef = userDocRef.collection('user-ingredients');

    List<String> removedNames = selectedIngredients.map((e) => e['name']!).toList();

    for (final ingredient in selectedIngredients) {
      final query = await ingredientsCollectionRef
          .where('name', isEqualTo: ingredient['name'])
          .where('category', isEqualTo: ingredient['category'])
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    }

    setState(() {
      selectedIngredients.clear();
    });

    await _getUserIngredients();
    Navigator.pop(context, removedNames);
  }

  Future<List<Map<String, String>>> _getUserIngredients() async {
    if( user == null){
      return [];
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference userDocRef = firestore.collection('users').doc(user!.uid);
    final ingredientsCollectionRef = userDocRef.collection('user-ingredients');

    final ingredientsSnapshot = await ingredientsCollectionRef.get();

    List<Map<String, String>> tempIngredients = [];


    for ( var doc in ingredientsSnapshot.docs) {
      tempIngredients.add({
        'name': doc['name'] as String,
        'category': doc['category'] as String,
      });
    }

    Set<String> categorySet = tempIngredients
        .map((item) => item['category']!)
        .toSet();

    setState(() {
      userIngredients = tempIngredients;
      categories = categorySet.toList();
      categories.sort();
      categories.remove('기타');
      categories.insert(0, '전체');
      categories.add('기타');
    });

    // print(userIngredients);
    // print(categories);

    return userIngredients;
  }

  void _filterIngredients(String query) {
    setState(() {
      filteredIngredients = query.isEmpty
          ? ingredientList
          : ingredientList.where((name) => name.contains(query)).toList();
    });
  }

  void _onCategoryChanged(int index) {
    setState(() {
      selectedCategoryIndex = index;
      _searchController.clear();
      _filterIngredients('');
    });
    // _loadIngredients();
  }

  List<Map<String, String>> get displayedIngredients {
    List<Map<String, String>> temp = userIngredients;

    if (selectedCategoryIndex != 0) {
      final selectedCategory = categories[selectedCategoryIndex];
      temp = temp
          .where((item) => item['category'] == selectedCategory)
          .toList();
    }

    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      temp = temp
          .where((item) =>
          item['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    return temp;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getUserIngredients();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener); // ★ 추가
    _scrollController.dispose(); // ★ 추가
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.textDark,
        title: Text('재료 삭제'),
      ),
      body: Column(
        children: [
          IngredientSearchBar(
              controller: _searchController,
              onChanged: _filterIngredients
          ),
          CategoryBar(
              categories: categories,
              selectedIndex: selectedCategoryIndex,
              onCategoryChanged: _onCategoryChanged
          ),
          SizedBox(height: 13,),
          Expanded(
            child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 120, // 내 냉장고와 동일한 높이
                ),
                itemCount: displayedIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = displayedIngredients[index];
                  final name = ingredient['name']!;
                  final category = ingredient['category']!;

                  final isSelected = selectedIngredients.contains(ingredient);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedIngredients.remove(ingredient); // 이미 선택된 거면 해제
                        } else {
                          selectedIngredients.add(ingredient); // 선택 추가
                        }
                      });
                      // print(selectedIngredients);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red[100] : Colors.white, // 배경색
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.grey, // 테두리 색
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),

                          // 🖼 재료 이미지
                          SizedBox(
                            height: screenSize.width * 0.13,
                            child: Image.asset(
                              'assets/ingredientIcons/$name.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.fastfood,
                                  size: 22,
                                  color: isSelected ? Colors.red[400] : Colors.grey,
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 4),

                          // 📝 재료 이름
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: screenSize.width * 0.038,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.red[800] : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          // 맨 위로 가기 버튼 (중앙 하단)
          if (_showScrollToTopButton)
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 20,
              bottom: 0,
              child: FloatingActionButton(
                heroTag: 'scrollToTop',
                mini: true,
                backgroundColor: AppColors.primaryColor,
                elevation: 4,
                onPressed: _scrollToTop,
                child: const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                ),
              ),
            ),
          // 확인 버튼 (우측 하단)
          if (selectedIngredients.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () async {
                  await _removeSelectIngredients();
                },
                child: const Text(
                  "확인",
                  style: TextStyle(color: AppColors.textWhite),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}