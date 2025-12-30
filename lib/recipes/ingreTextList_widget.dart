// 인식된 재료명들을 텍스트로 나열하기 위한 위젯!
// '재료확인' & '재료 편집' 화면에서 쓰임.
// 이 코드 자체에서 재료 목록이 바뀌는게 아니라 일단 StatelessWidget로 작성됨
// 미완

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/temp_ingre_provider.dart';

class IngreTextListWidget extends StatelessWidget {
  final List<String> detectedIngredients; // 외부에서 전달받는 리스트

  const IngreTextListWidget({super.key, required this.detectedIngredients});

  @override
  Widget build(BuildContext context) {
    final tempIngreProvider = context.read<TempIngredientProvider>();

    return Wrap(
      spacing: 8, // 아이템 사이 가로 간격
      runSpacing: 4, // 아이템 사이 세로 간격
      children: detectedIngredients.map((ingredient) {
        return Chip(
          label: Text(ingredient),
          backgroundColor: Colors.orange.shade100,
          deleteIcon: Icon(Icons.close, size: 16, color: Colors.red), // x 표시 빨갛게
          onDeleted: () {
            tempIngreProvider.removeIngredient(ingredient); // provider에서 제거
          },
        );
      }).toList(),
    );
  }
}