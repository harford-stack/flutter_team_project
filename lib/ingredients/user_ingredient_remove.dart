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
    Navigator.pop(context);
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
          Expanded(
            child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3/2,
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
                      child: Center(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: screenSize.width * 0.04,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.red[800] : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }
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
        onPressed: () async {
          // print(selectedIngredients);
          await _removeSelectIngredients();
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

//해야할거
//1.검색기능(완)
//2.카테고리 눌렀을 때 분류 기능(완)
//3.우측 하단에 fab 버튼 만들기(완)
//4.버튼 누르면 선택한 재료들 목록 print(완)
//5.버튼 누르면 해당 재료들 remove(완)