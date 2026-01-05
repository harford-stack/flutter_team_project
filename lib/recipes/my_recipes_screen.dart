import 'package:flutter/material.dart';
import '../auth/home_screen.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_drawer.dart';
// 추가된 import
import 'recipe_model.dart';
import 'recipe_service.dart';
import 'recipeDetail_screen.dart';

// drawer - 나의 레시피 화면
// 사용자가 저장한 레시피 목록을 표시하는 화면

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  bool _isLoading = false;

  // 추가된 변수: DB에서 가져올 Future 데이터
  late Future<List<RecipeModel>> _savedRecipes;

  // [추가된 변수] 선택된 레시피들의 String(제목)을 저장하는 집합(제목 중복은 없다고 전제)
  final Set<String> _selectedRecipeTitles = {};

  @override
  void initState() {
    super.initState();
    _savedRecipes = RecipeService().getSavedRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        appName: '나의 레시피',
      ),
      drawer: const CustomDrawer(),
      //backgroundColor: AppColors.backgroundColor,
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  /// 화면 본문 구성
  Widget _buildBody() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildRecipeList(),
        ),
        _buildBottomActions(),
      ],
    );
  }

  /// 상단 헤더 영역
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '저장한 레시피',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  /// 하단 고정 버튼 영역
  Widget _buildBottomActions() {
    bool hasSelection = _selectedRecipeTitles.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: hasSelection ? () async {
                setState(() => _isLoading = true);
                try {
                  for (String title in _selectedRecipeTitles) {
                    await RecipeService().deleteRecipeFromHistory(title);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('선택한 레시피가 삭제되었습니다.'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  print("선택 삭제 실패: $e");
                } finally {
                  setState(() {
                    _savedRecipes = RecipeService().getSavedRecipes();
                    _selectedRecipeTitles.clear();
                    _isLoading = false;
                  });
                }
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasSelection ? Colors.red : AppColors.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                hasSelection ? '${_selectedRecipeTitles.length}개 삭제하기' : '삭제 선택',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // 홈 화면으로 이동
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                '돌아가기',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 레시피 리스트 영역
  Widget _buildRecipeList() {
    return FutureBuilder<List<RecipeModel>>(
      future: _savedRecipes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('저장한 레시피가 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          );
        }

        final recipes = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            final bool isSelected = _selectedRecipeTitles.contains(recipe.title);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: Colors.white,
              // [수정] 기본 상태에서 그림자 살짝 부여
              elevation: isSelected ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  // [수정] 기본 상태일 때는 투명하게(테두리 없음), 선택 시만 강조
                  color: isSelected ? AppColors.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                leading: Checkbox(
                  activeColor: AppColors.primaryColor,
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedRecipeTitles.add(recipe.title!);
                      } else {
                        _selectedRecipeTitles.remove(recipe.title);
                      }
                    });
                  },
                ),
                title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(recipe.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RecipedetailScreen(recipe: recipe, isFromSaved: true)),
                  );
                  setState(() {
                    _savedRecipes = RecipeService().getSavedRecipes();
                    _selectedRecipeTitles.clear();
                  });
                },
              ),
            );
          },
        );
      },
    );
  }
}