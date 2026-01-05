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

  List<String> categoryTabs = [];
  List<String> ingredientList = [];
  List<String> filteredIngredients = [];

  int selectedCategoryIndex = 0;
  final Set<String> selectedIngredients = {};

  @override
  void initState() {
    super.initState();
    // 화면에 처음 들어올 때 선택된 재료 초기화
    selectedIngredients.clear();
    _loadData();
    _checkLoginStatus();
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
      print("로그인 상태: ${user.displayName}");
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
          Expanded(
            child: IngredientGrid(
              ingredients: filteredIngredients,
              selectedIngredients: selectedIngredients,
              onIngredientTap: _onIngredientTap,
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
          final selectedList = selectedIngredients.toList();

          // Provider에 임시 저장
          final provider = context.read<TempIngredientProvider>();
          
          if (widget.isInitialFlow) {
            // 최초 진입인 경우: 기존 재료 제거하고 새로 선택한 재료만 추가
            provider.clearAll();
            provider.addAll(selectedList);
          } else {
            // 재료 편집 화면에서 진입한 경우: 기존 재료 유지하고 새로 선택한 재료 추가
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
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
