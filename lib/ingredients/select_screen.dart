//재료 선택 화면

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_drawer.dart';
import '../providers/temp_ingre_provider.dart';
import 'widget_search_bar.dart';
import 'widget_category_bar.dart';
import 'widget_ingredient_grid.dart';
import 'service_ingredientFirestore.dart';
import '../recipes/ingreCheck_screen.dart';
import '../providers/temp_ingre_provider.dart';

class SelectScreen extends StatefulWidget {
  // ★ 최초 진입 여부 플래그 추가 (기본값 true)
  final bool isInitialFlow;

  // ★ 인그레 편집 등에서만 보이도록 하는 "직접 입력 재료 추가" 옵션
  final bool enableCustomInput;

  // ★ '내 냉장고'에 저장할지 여부 (true면 카테고리 선택 다이얼로그 표시)
  final bool saveToRefrigerator;

  const SelectScreen({
    super.key,
    this.isInitialFlow = true, // ★ 기본은 최초 진입
    this.enableCustomInput = false, // 기본은 숨김, 필요한 화면에서만 true로 전달
    this.saveToRefrigerator = false, // 기본은 레시피 추천용 (카테고리 불필요)
  });

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  final IngredientService _service = IngredientService();
  final TextEditingController _searchController = TextEditingController();

  // 목록에 없는 재료를 직접 입력해서 추가하는 용도
  final TextEditingController _customIngredientController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<String> categoryTabs = [];
  List<String> ingredientList = [];
  List<String> filteredIngredients = [];

  int selectedCategoryIndex = 0;
  final Set<String> selectedIngredients = {};

  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();
    // 화면에 처음 들어올 때 선택된 재료 초기화
    selectedIngredients.clear();
    _loadData();
    _checkLoginStatus();
    if(!widget.isInitialFlow){
      _syncWithProvider();
    }

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
    // 스크롤 위치가 200 이상이면 버튼 표시
    if (_scrollController.offset >= 200) {
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
    final ingredients = await _service.getIngredients(
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
      print("로그인 상태");
    } else {
      print("로그아웃 상태");
    }
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
    _loadIngredients();
  }

  void _onIngredientTap(String name) {
    setState(() {
      if (selectedIngredients.contains(name)) {
        selectedIngredients.remove(name);
      } else {
        selectedIngredients.add(name);
      }
    });
  }

  void _syncWithProvider() {
    final provider =
    Provider.of<TempIngredientProvider>(context, listen: false);

    print(provider.ingredients);
    // provider에 이미 담긴 재료를 선택 상태로 반영
    selectedIngredients
      ..clear()
      ..addAll(provider.ingredients);


  }

  // 레시피 추천용: TempIngredientProvider에만 추가
  void _addCustomIngredientToProvider(String ingredientName) {
    // 현재 선택 목록에 추가
    setState(() {
      selectedIngredients.add(ingredientName);
    });

    // 임시 재료 Provider에도 추가 (레시피 추천/편집 화면에서 바로 사용)
    context.read<TempIngredientProvider>().addIngredient(ingredientName);

    // 입력창 초기화 및 키보드 숨기기
    _customIngredientController.clear();
    FocusScope.of(context).unfocus();

    // 알림 표시 (setState 후에 표시) - 약간의 지연을 두어 확실히 표시
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$ingredientName 재료가 추가되었습니다.'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.fixed,
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    });
  }

  // 재료가 목록에 있는지 확인하고 카테고리 찾기 ('내 냉장고' 저장용)
  Future<void> _checkAndAddToRefrigerator(String ingredientName) async {
    // Firestore의 ingredients 컬렉션에서 해당 재료 찾기
    String? foundCategory;
    
    try {
      // 모든 카테고리를 순회하며 재료 찾기
      for (String category in categoryTabs) {
        if (category == '전체') continue;
        
        final ingredients = await _service.getIngredients(category);
        if (ingredients.contains(ingredientName)) {
          foundCategory = category;
          break;
        }
      }
    } catch (e) {
      print('재료 검색 중 오류: $e');
    }

    // 목록에 있으면 자동으로 카테고리 사용, 없으면 다이얼로그 표시
    if (foundCategory != null) {
      // 목록에 있는 재료: 자동으로 카테고리 사용하여 저장
      if (!mounted) return;
      
      // 입력창 초기화 및 키보드 숨기기
      _customIngredientController.clear();
      FocusScope.of(context).unfocus();
      
      // Firestore에 저장 (내부에서 저장 완료 알림 표시됨)
      await _saveToRefrigerator(ingredientName, foundCategory);
    } else {
      // 목록에 없는 재료: 카테고리 선택 다이얼로그 표시
      _showCategorySelectionDialog(ingredientName);
    }
  }

  // '내 냉장고' 저장용: 카테고리 선택 다이얼로그 표시
  void _showCategorySelectionDialog(String ingredientName) {
    // "전체" 카테고리는 제외하고 실제 카테고리만 표시
    final availableCategories = categoryTabs
        .where((cat) => cat != '전체')
        .toList();

    if (availableCategories.isEmpty) {
      // 카테고리가 없으면 기본값 '기타'로 저장
      _saveToRefrigerator(ingredientName, '기타');
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
                      _saveToRefrigerator(ingredientName, category);
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

  // Firestore '내 냉장고'에 저장
  Future<void> _saveToRefrigerator(String ingredientName, String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userIngreRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('user-ingredients');

      // 중복 체크
      final existingQuery = await userIngreRef
          .where('name', isEqualTo: ingredientName)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$ingredientName은(는) 이미 냉장고에 있습니다.'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.fixed,
              backgroundColor: AppColors.primaryColor,
            ),
          );
        }
        return;
      }

      // Firestore에 저장
      await userIngreRef.add({
        'name': ingredientName,
        'category': category,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // 현재 선택 목록에도 추가 (화면에서 바로 보이도록)
      setState(() {
        selectedIngredients.add(ingredientName);
      });

      // TempIngredientProvider에도 추가 (레시피 추천 화면에서도 사용 가능하도록)
      context.read<TempIngredientProvider>().addIngredient(ingredientName);

      // 입력창 초기화 및 키보드 숨기기
      _customIngredientController.clear();
      FocusScope.of(context).unfocus();

      // 알림 표시 (setState 후에 표시) - 약간의 지연을 두어 확실히 표시
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$ingredientName이(가) 냉장고에 추가되었습니다. (카테고리: $category)'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.fixed,
              backgroundColor: AppColors.primaryColor,
            ),
          );
        }
      });
    } catch (e) {
      print('냉장고 저장 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장 중 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      drawer: CustomDrawer(),
      appBar: CustomAppBar(
        appName: '재료 선택',
      ),
      body: Column(
        children: [
          IngredientSearchBar(
            controller: _searchController,
            onChanged: _filterIngredients,
          ),

          // ★ 인그레 편집 등 특정 플로우에서만 보이는 "목록에 없는 재료 직접 추가" 영역
          if (widget.enableCustomInput) ...[
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
                      final inputText =
                          _customIngredientController.text.trim();
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
                      if (selectedIngredients.contains(inputText)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이미 선택된 재료입니다.'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.fixed,
                          ),
                        );
                        return;
                      }

                      // '내 냉장고' 저장 모드면 목록 확인 후 처리
                      if (widget.saveToRefrigerator) {
                        _checkAndAddToRefrigerator(inputText).then((_) {
                          // 비동기 작업 완료 후 추가 처리 필요 시
                        }).catchError((e) {
                          print('재료 추가 중 오류: $e');
                        });
                      } else {
                        // 레시피 추천용: 바로 TempIngredientProvider에만 추가
                        _addCustomIngredientToProvider(inputText);
                      }
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
          ],
          CategoryBar(
            categories: categoryTabs,
            selectedIndex: selectedCategoryIndex,
            onCategoryChanged: _onCategoryChanged,
          ),
          SizedBox(height: 13,),
          Expanded(
            child: IngredientGrid(
              ingredients: filteredIngredients,
              selectedIngredients: selectedIngredients,
              onIngredientTap: _onIngredientTap,
              scrollController: _scrollController,
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          // 맨 위로 가기 버튼 (중앙 하단)
          if (_showScrollToTopButton)
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 20, // 화면 중앙에 배치
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
              right: 20,
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
                  final selectedList = selectedIngredients.toList();

                  // Provider에 임시 저장
                  final provider = context.read<TempIngredientProvider>();

                  if (widget.isInitialFlow) {
                    // 최초 진입인 경우: 기존 재료 제거하고 새로 선택한 재료만 추가
                    provider.clearAll();
                    provider.addAll(selectedList);
                  } else {
                    // 재료 편집 화면에서 진입한 경우: 기존 재료 유지하고 새로 선택한 재료 추가
                    provider.clearAll();
                    provider.addAll(selectedList);
                  }

                  // ★ SelectScreen은 이동 책임을 버리고 pop만 수행
                  Navigator.pop(context);

                  // ★ 최초 진입인 경우에만 ingreCheck로 이동
                  if (widget.isInitialFlow) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IngrecheckScreen(),
                      ),
                    );
                  }
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
