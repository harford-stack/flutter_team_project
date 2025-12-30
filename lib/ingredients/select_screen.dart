//재료 선택 화면

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../providers/temp_ingre_provider.dart';
import 'widget_search_bar.dart';
import 'widget_category_bar.dart';
import 'widget_ingredient_grid.dart';
import 'service_ingredientFirestore.dart';
import '../recipes/ingreCheck_screen.dart';

// import 'package:firebase_core/firebase_core.dart';
// import '../firebase_options.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MaterialApp(
//     home: SelectScreen(),
//   ));
// }

class SelectScreen extends StatefulWidget {
  const SelectScreen({super.key});

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
    _loadData();
    _checkLoginStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existingIngredients =
          context.read<TempIngredientProvider>().ingredients;

      setState(() {
        selectedIngredients.addAll(existingIngredients);
      });
    });
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
                context.read<TempIngredientProvider>().addAll(selectedList);

                // 재료 확인 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const IngrecheckScreen(),
                  ),
                );
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