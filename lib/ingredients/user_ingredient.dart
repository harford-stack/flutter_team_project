import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import 'widget_search_bar.dart';
import 'widget_category_bar.dart';
import 'widget_ingredient_grid.dart';
import 'service_ingredientFirestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
    home: UserIngredient(),
  ));
}

class UserIngredient extends StatefulWidget {
  const UserIngredient({super.key});

  @override
  State<UserIngredient> createState() => _UserIngredientState();
}

class _UserIngredientState extends State<UserIngredient> {
  final IngredientService _service = IngredientService();
  final TextEditingController _searchController = TextEditingController();

  List<String> categoryTabs = [];
  List<String> ingredientList = [];
  List<String> filteredIngredients = [];

  int selectedCategoryIndex = 0;
  final Set<String> selectedIngredients = {};

  Future<void> _loadIngredients() async {
    final ingredients = await _service.getIngredients(
        categoryTabs[selectedCategoryIndex]
    );

    setState(() {
      ingredientList = ingredients;
      filteredIngredients = ingredients;
    });
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
  void initState() {
    super.initState();
    _loadData();
    _checkLoginStatus();
  }

  Future<void> _loadData() async {
    categoryTabs = await _service.getCategories();
    await _loadIngredients();
  }

  void _checkLoginStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("로그인 상태: ${user.displayName}");
    } else {
      print("로그아웃 상태");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomAppBar(
        appName: '내 재료',
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
          // print(selectedIngredients);
          // List<String> selectedList = selectedIngredients.toList();
          // Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //         builder: (_)=> IngrecheckScreen(selectedIngredients: selectedList)
          //     )
          // );

          final selectedList = selectedIngredients.toList();

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
