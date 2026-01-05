// community/widgets/shared/category_tabs.dart

import 'package:flutter/material.dart';
import '../../../common/app_colors.dart';

/// 小红书风格分类标签栏
///
/// 特点：
/// - 简洁干净，只有文字 + 动态下划线
/// - 选中时下划线从无到有，平滑过渡
/// - 无背景色、无圆角、无阴影
class CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const CategoryTabs({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // 左对齐，像小红书
        children: categories.map((category) {
          final isSelected = selectedCategory == category;

          return GestureDetector(
            onTap: () => onCategoryChanged(category),
            child: Container(
              margin: EdgeInsets.only(right: 24), // 标签之间间距
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 文字
                  Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),

                  SizedBox(height: 4),

                  // ✅ 动态下划线（仿小红书）
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: isSelected ? 20 : 0, // 选中时显示，未选中时宽度为0
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