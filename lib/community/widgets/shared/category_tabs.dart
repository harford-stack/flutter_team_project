// ==================================================================================
// 4. category_tabs.dart - 카테고리 탭 (공유 컴포넌트)
// ==================================================================================
// community/widgets/shared/category_tabs.dart

// 사용처: 커뮤니티 화면, 내가 쓴 게시글, 북마크 목록

import 'package:flutter/material.dart';
import '../../../common/app_colors.dart';

/// 카테고리 탭 컴포넌트
/// 특징:
/// - 텍스트 + 동적 밑줄만 표시
/// - 배경색, 둥근 모서리, 그림자 없음
class CategoryTabs extends StatelessWidget {
  /// =====================================================================================
  /// 필드
  /// =====================================================================================
  final List<String> categories; // 카테고리 목록
  final String selectedCategory; // 선택된 카테고리
  final Function(String) onCategoryChanged; // 카테고리 변경 콜백

  /// =====================================================================================
  /// 생성자
  /// =====================================================================================
  const CategoryTabs({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  /// =====================================================================================
  /// UI 구현
  /// =====================================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        // 카테고리 목록을 순회하여 탭 생성
        children: categories.map((category) {
          final isSelected = selectedCategory == category;

          return GestureDetector(
            // 중요: 탭 클릭 시 부모 컴포넌트에 선택된 카테고리 전달
            // 부모가 setState로 _selectedCategory 업데이트
            // → 자식이 새 selectedCategory 받음
            // → isSelected 재계산
            onTap: () => onCategoryChanged(category),
            child: Container(
              margin: EdgeInsets.only(right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 텍스트
                  Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),

                  SizedBox(height: 4),

                  // 동적 밑줄 (애니메이션)
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut, // 부드러운 애니메이션
                    width: isSelected ? 50 : 0, // 선택 시 너비 확장
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
