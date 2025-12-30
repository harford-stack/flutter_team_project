import 'package:flutter/material.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_drawer.dart';

/// 나의 레시피 화면
/// 사용자가 저장한 레시피 목록을 표시하는 화면
class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  bool _isLoading = false;

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

  /// 레시피 리스트 영역
  /// 다른 팀원이 이 부분에 리스트 구현
  Widget _buildRecipeList() {
    // TODO: 다른 팀원이 리스트 구현 예정
    // 현재는 빈 화면 또는 플레이스홀더 표시
    
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

