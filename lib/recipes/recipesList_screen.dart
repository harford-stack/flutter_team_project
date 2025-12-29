// ai 레시피 생성 결과 목록 화면

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_team_project/recipes/recipeDetail_screen.dart';

class RecipeslistScreen extends StatefulWidget {
  final List<dynamic> recipes; // 데이터를 받을 변수 추가
  const RecipeslistScreen({super.key, required this.recipes}); // 생성자 수정

  @override
  State<RecipeslistScreen> createState() => _RecipeslistScreenState();
}

class _RecipeslistScreenState extends State<RecipeslistScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // 세로 중앙 배치를 위해 필수
          crossAxisAlignment: CrossAxisAlignment.start, // 자식들을 왼쪽 정렬 (Text 기준)
          children: [
            // 1) 제목 텍스트: 리스트의 패딩값(20)과 동일하게 맞춰서 왼쪽 정렬 효과
            const Padding(
              padding: EdgeInsets.only(left: 20.0, bottom: 10.0),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined),
                  SizedBox(width: 10,),
                  Text(
                    "완성된 레시피 목록",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }
}
// 레시피 카드 위젯 (데이터 반영, 인자에 recipe 추가)
Widget _buildRecipeCard(BuildContext context, dynamic recipe) {
  return GestureDetector(
    onTap: () {
      // 개별 카드를 눌렀을 때 상세페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RecipedetailScreen(),
        ),
      );
    },

    child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[300], // 와이어프레임의 회색 배경
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                recipe["요리 제목"] ?? "제목 없음", // JSON 키값 적용
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // 북마크 아이콘 버튼
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.bookmark_border, size: 24),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            recipe["과정"][0] ?? "상세 내용 없음", // 첫 번째 조리 과정 미리보기
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              // 첫 번째 재료 이름 표시
              _buildIngredientTag(recipe["재료"][0]["이름"]),
              const SizedBox(width: 12),
              Text(
                "외 ${recipe["재료"].length - 1}개",
                style: TextStyle(fontSize: 14, color: Colors.black54),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
  );
}
