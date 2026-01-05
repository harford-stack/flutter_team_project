// ai 레시피 생성 결과 목록 화면

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_team_project/recipes/recipeDetail_screen.dart';
import 'package:flutter_team_project/recipes/recipe_service.dart';
import 'package:http/http.dart';
import '../auth/home_screen.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_drawer.dart';
import '../providers/temp_ingre_provider.dart';
import 'recipe_model.dart'; // ★ 추가: 모델 임포트
import 'package:flutter_team_project/common/bookmark_button.dart';
import 'package:provider/provider.dart';

class RecipeslistScreen extends StatefulWidget {
  final List<RecipeModel> recipes; // 데이터를 받을 변수 추가
  const RecipeslistScreen({super.key, required this.recipes}); // 생성자 수정

  @override
  State<RecipeslistScreen> createState() => _RecipeslistScreenState();
}

class _RecipeslistScreenState extends State<RecipeslistScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경을 흰색으로 유지
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // 세로 중앙 배치를 위해 필수
          crossAxisAlignment: CrossAxisAlignment.stretch, // ★ 수정: 자식들을 가로로 꽉 채우기 위해 변경
          children: [
            // 1) 제목 텍스트: 리스트의 패딩값(20)과 동일하게 맞춰서 왼쪽 정렬 효과
            Padding(
              padding: EdgeInsets.only(left: 20.0, bottom: 10.0),
              child: Row(
                children: [
                  Image.asset("assets/recipe_list.png", width: 270),
                  //Icon(Icons.receipt_long_outlined),
                  // SizedBox(width: 10,),
                  // Text(
                  //   "완성된 레시피 목록",
                  //   style: TextStyle(
                  //     fontSize: 25,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                ],
              ),
            ),

            // 2) 리스트 영역
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20), // 좌우 여백 20
              itemCount: widget.recipes.length, // AI가 준 개수만큼 (기본 3개)
              itemBuilder: (context, index) {
                // 실제 데이터를 카드 위젯에 전달
                return _buildRecipeCard(context, widget.recipes[index]);
              },
            ),

            const SizedBox(height: 20,), // const 추가 (성능 최적화)

            // ★ 수정: 버튼 좌우 여백을 위해 Padding으로 감싸고 높이 지정을 위해 SizedBox 사용
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                height: 55, // 상세 페이지와 동일한 높이
                child: ElevatedButton(
                    onPressed: (){
                      // 홈 화면 이동 전에 provider에 있는 임시 재료 목록 지우기
                      context.read<TempIngredientProvider>().clearAll();

                      // 그 후 홈 화면으로 이동
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)) // 상세와 통일
                    ),
                    child: Text(
                      "홈으로",
                      style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 18),
                    )
                ),
              ),
            ),

            // ★ 수정: 문구를 가운데 정렬하기 위해 Center로 감쌈
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  "홈으로 이동 시 생성된 레시피는 소멸됩니다.",
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
// 레시피 카드 위젯 (데이터 반영, 인자에 recipe 추가)
Widget _buildRecipeCard(BuildContext context, RecipeModel recipe) {
  // ★ 추가: 파생값은 함수 맨 위에서 계산
  final extraCount = recipe.ingredients.length - 1;

  return GestureDetector(
    onTap: () {
      // 개별 카드를 눌렀을 때 상세페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          // ★ 상세화면 생성자에서 RecipeModel을 받도록 수정하면 데이터 전달 가능
          builder: (context) => RecipedetailScreen(recipe: recipe),
        ),
      );
    },

    child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        //color: Colors.grey[300], // 와이어프레임의 회색 배경
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2), // 그림자 색상
            spreadRadius: 2, // 그림자 퍼지는 범위
            blurRadius: 10, // 그림자의 흐림 정도
            offset: Offset(0, 0), // ★ 추가: 4면 동일하게 동동 뜬 느낌
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                recipe.title, // ★ 변경: JSON 키값 대신 모델 속성 사용
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            recipe.description, // ★ 변경: 모델에 저장된 요약(첫 번째 과정) 사용
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              // 첫 번째 재료 이름 표시
              _buildIngredientTag(
                  recipe.ingredients.isNotEmpty
                      ? recipe.ingredients[0]["이름"]!
                      : "재료"
              ),
              const SizedBox(width: 12),

              // ~ 외 n개 표시할 때, 재료 개수가 0개나 마이너스인 경우 피하도록
              if (extraCount > 0)
                Text(
                  "외 $extraCount개",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

// 하단 재료 태그 위젯
Widget _buildIngredientTag(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.secondaryColor, // ★ 추가: 재료 부분 secondaryColor 적용
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white, // ★ 추가: 글자 색상을 흰색으로 변경
      ),
    ),
  );
}