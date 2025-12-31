import 'package:flutter/material.dart';
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
    // 화면 초기화 시 DB에서 데이터 호출
    _savedRecipes = RecipeService().getSavedRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        appName: '나의 레시피',
      ),
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  /// 화면 본문 구성
  Widget _buildBody() {
    return Column(
      children: [
        // 상단 안내 영역 (선택사항)
        _buildHeader(),
        // 리스트 영역 (다른 팀원이 구현할 부분)
        Expanded(
          child: _buildRecipeList(),
        ),
        // [추가된 위젯] 하단 고정 선택 삭제 버튼
        _buildDeleteButton(),
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
          // 정렬/필터 버튼 영역 (필요시 추가)
          // IconButton(
          //   icon: const Icon(Icons.sort),
          //   onPressed: () {
          //     // 정렬 옵션 표시
          //   },
          // ),
        ],
      ),
    );
  }

  /// [추가된 메서드] 하단 고정 삭제 버튼 영역 구성
  Widget _buildDeleteButton() {
    bool hasSelection = _selectedRecipeTitles.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        // [수정] 선택 삭제 로직 연결
        onPressed: hasSelection ? () async {
          // [추가된 로직] DB 삭제 시작
          setState(() => _isLoading = true); // 로딩 시작

          try {
            // 선택된 모든 제목에 대해 삭제 메서드 반복 호출
            for (String title in _selectedRecipeTitles) {
              await RecipeService().deleteRecipeFromHistory(title);
            }
            print("선택한 레시피들 DB 삭제 성공");
            // 삭제 성공 시 스낵바 표시
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('선택한 레시피가 삭제되었습니다.'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating, // 선택사항: 공중에 뜬 형태
                ),
              );
            }
          } catch (e) {
            print("선택 삭제 실패: $e");
          } finally {
            // 삭제 완료 후 데이터 새로고침 및 상태 초기화
            setState(() {
              _savedRecipes = RecipeService().getSavedRecipes();
              _selectedRecipeTitles.clear();
              _isLoading = false; // 로딩 종료
            });
          }
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          hasSelection ? '${_selectedRecipeTitles.length}개 삭제하기' : '삭제할 레시피를 선택하세요',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 레시피 리스트 영역
  /// 다른 팀원이 이 부분에 리스트 구현
  Widget _buildRecipeList() {
    // TODO: 다른 팀원이 리스트 구현 예정
    // 현재는 빈 화면 또는 플레이스홀더 표시

    // FutureBuilder를 사용하여 실시간으로 DB 데이터를 기다림
    return FutureBuilder<List<RecipeModel>>(
      future: _savedRecipes,
      builder: (context, snapshot) {
        // 로딩 중 표시
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 데이터가 없거나 비어있는 경우 기존 UI 반환
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '저장한 레시피가 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '레시피를 저장하면 여기에 표시됩니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        // 데이터가 있는 경우 리스트 뷰 반환
        final recipes = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            // [추가] 현재 카드의 선택 여부 확인
            final bool isSelected = _selectedRecipeTitles.contains(recipe.title);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              // [수정] 선택 시 테두리 색상 강조 추가
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                // [수정] 체크박스 공간 확보를 위해 패딩 소폭 조정
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                // [수정] 기존 CircleAvatar 대신 체크박스를 leading으로 배치
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
                title: Text(
                  recipe.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  recipe.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  // 레시피 상세 화면으로 이동하고, 그 화면이 닫힐 때까지 기다림
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipedetailScreen(recipe: recipe),
                    ),
                  );

                  // 상세 화면에서 돌아오면(back키 포함) DB 데이터를 다시 읽어와서 화면을 갱신
                  setState(() {
                    _savedRecipes = RecipeService().getSavedRecipes();
                    // [추가] 상세 페이지 다녀온 후 선택 상태 초기화 (필요 시 유지 가능)
                    _selectedRecipeTitles.clear();
                  });
                },
              ),
            );
          },
        );
      },
    );

    // 다른 팀원이 구현할 때 사용할 예시 구조:
    // return ListView.builder(
    //   padding: const EdgeInsets.all(16.0),
    //   itemCount: recipes.length, // recipes 리스트
    //   itemBuilder: (context, index) {
    //     return _buildRecipeCard(recipes[index]);
    //   },
    // );
  }

/// 레시피 카드 위젯 (예시, 다른 팀원이 구현)
/// 다른 팀원이 이 메서드를 구현하거나 수정할 예정
// Widget _buildRecipeCard(Recipe recipe) {
//   return Card(
//     margin: const EdgeInsets.only(bottom: 12),
//     child: ListTile(
//       leading: Image.network(recipe.thumbnailUrl),
//       title: Text(recipe.title),
//       subtitle: Text(recipe.description),
//       onTap: () {
//         // 레시피 상세 화면으로 이동
//       },
//     ),
//   );
// }
}