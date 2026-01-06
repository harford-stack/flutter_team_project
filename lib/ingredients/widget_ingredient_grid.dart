import 'package:flutter/material.dart';
import '../../common/app_colors.dart';

class IngredientGrid extends StatelessWidget {
  final List<String> ingredients;
  final Set<String> selectedIngredients;
  // final Set<String> disabledIngredients;
  final ValueChanged<String> onIngredientTap;
  final ScrollController? scrollController; // ★ 추가

  const IngredientGrid({
    super.key,
    required this.ingredients,
    required this.selectedIngredients,
    required this.onIngredientTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // final Size screenSize = MediaQuery.of(context).size;

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: ingredients.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final ingredientName = ingredients[index];
        final isSelected = selectedIngredients.contains(ingredientName);
        final Size screenSize = MediaQuery.of(context).size;

        return GestureDetector(
          onTap: () => onIngredientTap(ingredientName),
          child: Container(
            decoration: BoxDecoration(
              // color: Colors.grey.shade300,
              color: AppColors.textWhite,
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.1), // 그림자 색
                blurRadius: 8,        // 퍼짐 정도
                spreadRadius: 1,      // 그림자 크기
                offset: Offset(0, 2), // x, y 위치 (아래쪽)
              )],
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.secondaryColor, width: 2)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/ingredientIcons/$ingredientName.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.fastfood, size: 32),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        ingredientName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenSize.width * 0.038,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  const Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.secondaryColor,
                      size: 20,
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}