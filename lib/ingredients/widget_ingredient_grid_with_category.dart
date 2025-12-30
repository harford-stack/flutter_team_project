import 'package:flutter/material.dart';
import '../common/app_colors.dart';

class IngredientGridWithCategory extends StatelessWidget {
  final List<String> ingredients;
  final Map<String, String> selectedIngredients;
  final Function(String) onIngredientTap;

  const IngredientGridWithCategory({
    super.key,
    required this.ingredients,
    required this.selectedIngredients,
    required this.onIngredientTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        final isSelected = selectedIngredients.containsKey(ingredient);

        return GestureDetector(
          onTap: () => onIngredientTap(ingredient),
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
                    ingredient,
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