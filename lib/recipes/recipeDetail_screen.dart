// 레시피 상세보기 화면

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RecipedetailScreen extends StatefulWidget {
  const RecipedetailScreen({super.key});

  @override
  State<RecipedetailScreen> createState() => _RecipedetailScreenState();
}

class _RecipedetailScreenState extends State<RecipedetailScreen> {
  // 나중에 AI로부터 받을 데이터를 위한 변수 예시
  final String recipeTitle = "스크램블 에그";
  final List<String> ingredients = ["달걀", "우유", "소금", "후추", "버터"];
  final String recipeInstruction = "1. 달걀을 그릇에 풀고 우유와 소금을 넣습니다.\n"
      "2. 팬을 중불로 달구고 버터를 녹입니다.\n"
      "3. 달걀물을 붓고 몽글몽글해질 때까지 저어줍니다.\n"
      "4. 원하는 익힘 정도가 되면 접시에 담아 후추를 뿌립니다.";


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 나중에 지정색으로 받을거임
      appBar: AppBar(
        // 임시 앱바임!!! 나중에 공통 앱바로 넣을거임 (뒤로가기 기능 없음)
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Icon(Icons.arrow_back_ios, color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 및 북마크 아이콘 섹션
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  recipeTitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.bookmark_border, size: 30),
                ),
              ],
            ),
            SizedBox(height: 30),

            // 재료 섹션
            Text(
              "재료",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8.0, // 가로 간격
              runSpacing: 8.0, // 세로 간격 (줄바꿈 시)
              children: ingredients.map((item) => _buildIngredientChip(item)).toList(),
            ),
            SizedBox(height: 40),

            // 레시피 설명 섹션
            Text(
              "레시피 설명",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200], // 이미지의 회색 배경 재현
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                recipeInstruction,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6, // 줄간격 조절로 가독성 향상
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 50), // 하단 여백
          ],
        ),
      ),
    );
  }

  // 재료 칩 위젯 생성 함수
  Widget _buildIngredientChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}