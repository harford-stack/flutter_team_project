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
  
  // 목록에 없는 재료를 직접 입력해서 추가하는 용도
  final TextEditingController _customIngredientController = TextEditingController();

  List<String> categoryTabs = [];
  List<Map<String, String>> ingredientList = [];
  List<Map<String, String>> filteredIngredients = [];

  int selectedCategoryIndex = 0;
  final Map<String, String> selectedIngredients = {};

  Set<String> disabledIngredients = {};

  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkLoginStatus();
    _getUserIngredients();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _customIngredientController.dispose();
    super.dispose();
  }

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

    sortedIngredients.sort((a, b) {
      return a['name']!.compareTo(b['name']!);
    });

    otherIngredients.sort((a, b) {
      return a['name']!.compareTo(b['name']!);
    });

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
    
    print("=== _saveIngredients 디버깅 ===");
    print("선택된 재료 개수: ${selectedIngredients.length}");
    print("선택된 재료 목록: ${selectedIngredients.keys.toList()}");
    print("기존 냉장고 재료 개수: ${existingIngredients.length}");
    print("기존 냉장고 재료 목록: $existingIngredients");

    List<String> duplicateIngredients = [];
    int addedCount = 0;

    for (var ingredient in selectedIngredients.entries) {
      print("재료 체크 중: ${ingredient.key}");
      print("기존 재료에 포함되어 있는가? ${existingIngredients.contains(ingredient.key)}");
      
      if (existingIngredients.contains(ingredient.key)) {
        duplicateIngredients.add(ingredient.key);
        print("재료 ${ingredient.key}는 이미 추가되어 있습니다. 건너뜁니다.");
        continue;
      }

      final ingredientData = {
        'name' : ingredient.key,
        'category' : ingredient.value,
        'addedAt' : FieldValue.serverTimestamp(),
      };

      await ingredientsCollectionRef.add(ingredientData);
      addedCount++;
      print("재료 ${ingredient.key}가 추가되었습니다.");
    }

    // 알림 표시
    if (mounted) {
      if (duplicateIngredients.isNotEmpty && addedCount == 0) {
        // 모두 중복인 경우
        final duplicateList = duplicateIngredients.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$duplicateList${duplicateIngredients.length == 1 ? '은(는)' : '은(는)'} 이미 냉장고에 있습니다.'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.fixed,
            backgroundColor: AppColors.primaryColor,
          ),
        );
      } else if (duplicateIngredients.isNotEmpty && addedCount > 0) {
        // 일부 중복인 경우
        final duplicateList = duplicateIngredients.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$addedCount개의 재료가 추가되었습니다. ($duplicateList${duplicateIngredients.length == 1 ? '은(는)' : '은(는)'} 이미 냉장고에 있습니다)'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.fixed,
            backgroundColor: AppColors.primaryColor,
          ),
        );
      } else if (addedCount > 0) {
        // 모두 새로 추가된 경우
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$addedCount개의 재료가 냉장고에 추가되었습니다.'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.fixed,
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    }

    // 재료가 추가되었을 때만 화면을 닫음
    if (addedCount > 0) {
      Navigator.pop(context);
    }
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
            // 목록에 없는 재료 직접 입력 영역
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customIngredientController,
                      decoration: InputDecoration(
                        hintText: '목록에 없는 재료 이름 직접 입력',
                        prefixIcon: const Icon(Icons.edit),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final inputText = _customIngredientController.text.trim();
                      if (inputText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('재료 이름을 입력해주세요.'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.fixed,
                          ),
                        );
                        return;
                      }

                      // 이미 선택된 재료라면 중복 추가 방지
                      if (selectedIngredients.containsKey(inputText)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이미 선택된 재료입니다.'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.fixed,
                          ),
                        );
                        return;
                      }

                      // 이미 냉장고에 있는 재료인지 확인
                      if (disabledIngredients.contains(inputText)) {
                        // 입력창 초기화 및 키보드 숨기기
                        _customIngredientController.clear();
                        FocusScope.of(context).unfocus();
                        
                        // 알림 즉시 표시
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$inputText은(는) 이미 냉장고에 있습니다.'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.fixed,
                            backgroundColor: AppColors.primaryColor,
                          ),
                        );
                        return;
                      }

                      // 목록에 있는 재료인지 확인하고 카테고리 찾기
                      _checkAndAddCustomIngredient(inputText).then((_) {
                        // 비동기 작업 완료 후 추가 처리 필요 시
                      }).catchError((e) {
                        print('재료 추가 중 오류: $e');
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '추가',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13), // 카테고리 영역과의 간격 추가
            CategoryBar(
              categories: categoryTabs,
              selectedIndex: selectedCategoryIndex,
              onCategoryChanged: _onCategoryChanged,
            ),
            SizedBox(height: 13,),
            Expanded(
              child: IngredientGridWithCategory(
                ingredients: filteredIngredients.map((item) => item['name']!).toList(),
                selectedIngredients: selectedIngredients,
                disabledIngredients: disabledIngredients,
                scrollController: _scrollController,
                onIngredientTap: (name) {
                  // 이미 선택된 재료는 클릭할 수 없도록 처리
                  // if (selectedIngredients.containsKey(name)) return;

                  final item = filteredIngredients.firstWhere((item) => item['name'] == name);
                  _onIngredientTap(item);
                },
              ),
            ),
          ],
        ),
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
                  color: AppColors.textWhite,
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
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // 재료가 목록에 있는지 확인하고 카테고리 찾기
  Future<void> _checkAndAddCustomIngredient(String ingredientName) async {
    print("=== _checkAndAddCustomIngredient 호출됨 ===");
    print("입력된 재료 이름: $ingredientName");
    
    // Firestore의 ingredients 컬렉션에서 해당 재료 찾기
    String? foundCategory;
    
    try {
      // 모든 카테고리를 순회하며 재료 찾기
      for (String category in categoryTabs) {
        if (category == '전체') continue;
        
        final ingredients = await _getCategoryIngre.getIngredientsWithCategory(category);
        final found = ingredients.firstWhere(
          (item) => item['name'] == ingredientName,
          orElse: () => {},
        );
        
        if (found.isNotEmpty) {
          foundCategory = found['category'] as String?;
          break;
        }
      }
    } catch (e) {
      print('재료 검색 중 오류: $e');
    }

    // 이미 냉장고에 있는 재료인지 먼저 확인
    if (disabledIngredients.contains(ingredientName)) {
      if (!mounted) return;
      
      // 입력창 초기화 및 키보드 숨기기
      _customIngredientController.clear();
      FocusScope.of(context).unfocus();
      
      // 알림 즉시 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$ingredientName은(는) 이미 냉장고에 있습니다.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryColor,
        ),
      );
      return;
    }

    // 목록에 있으면 자동으로 카테고리 사용, 없으면 다이얼로그 표시
    if (foundCategory != null) {
      // 목록에 있는 재료: 자동으로 카테고리 사용
      if (!mounted) return;
      
      // 입력창 초기화 및 키보드 숨기기
      _customIngredientController.clear();
      FocusScope.of(context).unfocus();
      
      // 재료 추가
      _addCustomIngredient(ingredientName, foundCategory, showNotification: false);
      
      // 알림 표시 (setState 완료 후) - 약간의 지연을 두어 확실히 표시
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$ingredientName 재료가 추가되었습니다. (카테고리: $foundCategory)'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.fixed,
              backgroundColor: AppColors.primaryColor,
            ),
          );
        }
      });
    } else {
      // 목록에 없는 재료: 카테고리 선택 다이얼로그 표시
      _showCategorySelectionDialog(ingredientName);
    }
  }

  // 카테고리 선택 다이얼로그 표시
  void _showCategorySelectionDialog(String ingredientName) {
    // "전체" 카테고리는 제외하고 실제 카테고리만 표시
    final availableCategories = categoryTabs
        .where((cat) => cat != '전체')
        .toList();

    if (availableCategories.isEmpty) {
      // 카테고리가 없으면 기본값 '기타'로 저장
      _addCustomIngredient(ingredientName, '기타', showNotification: true);
      // 입력창 초기화 및 키보드 숨기기
      _customIngredientController.clear();
      FocusScope.of(context).unfocus();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                '카테고리 선택',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$ingredientName의 카테고리를 선택해주세요.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              // 카테고리 버튼들 (Wrap으로 나열)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableCategories.map((category) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      // 입력창 초기화 및 키보드 숨기기
                      _customIngredientController.clear();
                      FocusScope.of(context).unfocus();
                      
                      _addCustomIngredient(ingredientName, category, showNotification: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // 취소 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 직접 입력한 재료를 선택 목록에 추가
  void _addCustomIngredient(String ingredientName, String category, {bool showNotification = false}) {
    // 이미 냉장고에 있는 재료인지 확인
    if (disabledIngredients.contains(ingredientName)) {
      // 알림 즉시 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$ingredientName은(는) 이미 냉장고에 있습니다.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryColor,
        ),
      );
      return;
    }

    // 현재 선택 목록에 추가
    setState(() {
      selectedIngredients[ingredientName] = category;
    });
    
    // 알림 표시가 필요한 경우 (setState 후 바로 표시)
    if (showNotification) {
      // setState 완료 후 알림 표시 - 약간의 지연을 두어 확실히 표시
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$ingredientName 재료가 추가되었습니다. (카테고리: $category)'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.fixed,
              backgroundColor: AppColors.primaryColor,
            ),
          );
        }
      });
    }
  }
}
