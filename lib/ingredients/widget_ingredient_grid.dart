import 'package:flutter/material.dart';
import '../../common/app_colors.dart';

class IngredientGrid extends StatelessWidget {
  final List<String> ingredients;
  final Set<String> selectedIngredients;
  final ValueChanged<String> onIngredientTap;

  const IngredientGrid({
    super.key,
    required this.ingredients,
    required this.selectedIngredients,
    required this.onIngredientTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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

        return GestureDetector(
          onTap: () => onIngredientTap(ingredientName),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.secondaryColor, width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    ingredientName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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