import 'package:flutter/material.dart';
import '../../common/app_colors.dart';

class CategoryBar extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategoryChanged;

  const CategoryBar({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: (){
              onCategoryChanged(index);
              print(categories[index]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryColor),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}