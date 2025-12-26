// 레시피 생성 목록화면

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_team_project/recipes/recipeDetail_screen.dart';

class RecipeslistScreen extends StatefulWidget {
  const RecipeslistScreen({super.key});

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
              itemCount: 3,
              itemBuilder: (context, index) {
                return _buildRecipeCard(context); // 현재 화면의 context 전달
              },
            ),
          ],
        ),
      ),
    );
  }
}
// 레시피 카드 위젯 (↓인자값으로 BuildContext를 받음!)
Widget _buildRecipeCard(BuildContext context) {
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
              const Text(
                "스크램블 에그",
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
          const SizedBox(height: 10),
          const Text(
            "달걀을 깨서 ...... 달걀을 볶아\n소금과 후추로....",
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildIngredientTag("달걀"),
              const SizedBox(width: 8),
              _buildIngredientTag("달걀"),
              const SizedBox(width: 12),
              const Text(
                "외 5개",
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
