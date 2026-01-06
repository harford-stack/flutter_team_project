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
    final Size screenSize = MediaQuery.of(context).size;

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 120, // 내 냉장고와 동일한 높이
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
              color: isDisabled
                  ? Colors.grey.shade200
                  : isSelected
                  ? AppColors.secondaryColor.withOpacity(0.15)
                  : AppColors.textWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDisabled
                  ? null
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: isSelected
                ? Border.all(
                    color: AppColors.secondaryColor,
                    width: 2
                  )
                : null
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(height: 10,),
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/ingredientIcons/$ingredient.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 5,),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          ingredient,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenSize.width * 0.038,
                            fontWeight: FontWeight.bold,
                            color: isDisabled
                                ? Colors.grey
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8,),
                  ],
                ),

                if (isDisabled)
                  const Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(Icons.lock, size: 18, color: Colors.grey),
                  ),

                if (isSelected)
                  const Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppColors.secondaryColor,
                    ),
                  ),

                SizedBox(height: 10,),
              ],
            ),
          ),

        );
      },
    );
  }
}