//재료 선택 화면

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
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

  const SelectScreen({
    super.key,
    this.isInitialFlow = true, // ★ 기본은 최초 진입
  });

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  final IngredientService _service = IngredientService();
  final TextEditingController _searchController = TextEditingController();
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
    // TODO: implement dispose
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
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
