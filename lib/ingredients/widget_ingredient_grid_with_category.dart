import 'package:flutter/material.dart';
import '../common/app_colors.dart';

class IngredientGridWithCategory extends StatelessWidget {
  final List<String> ingredients;
  final Map<String, String> selectedIngredients;
  final Function(String) onIngredientTap;
  final Set<String> disabledIngredients;
  final ScrollController? scrollController;

  const IngredientGridWithCategory({
    super.key,
    required this.ingredients,
    required this.selectedIngredients,
    required this.onIngredientTap,
    required this.disabledIngredients,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 60, // 내 냉장고와 동일한 높이
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        final isSelected = selectedIngredients.containsKey(ingredient);
        final isDisabled = disabledIngredients.contains(ingredient);

        return GestureDetector(
          onTap: isDisabled ? null : () => onIngredientTap(ingredient),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: isDisabled
                ? null
                : [BoxShadow(
                color: Colors.black.withOpacity(0.1), // 그림자 색
                  blurRadius: 8,        // 퍼짐 정도
                  spreadRadius: 1,      // 그림자 크기
                  offset: Offset(0, 2), // x, y 위치 (아래쪽)
                )],
              color: isDisabled
                  ? Colors.grey.shade200
                  : isSelected
                    ? AppColors.secondaryColor.withOpacity(0.15)
                    : AppColors.textWhite,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.secondaryColor, width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    ingredient,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDisabled ? Colors.grey : AppColors.textDark,
                    ),
                  ),
                ),

                // 🔒 이미 등록된 재료
                if (isDisabled)
                  const Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(
                      Icons.lock,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ),

                // ✅ 새로 선택한 재료
                if (isSelected)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.secondaryColor,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}