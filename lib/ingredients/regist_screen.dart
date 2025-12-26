import 'package:flutter/material.dart';

class IngredientRegistScreen extends StatelessWidget {
  const IngredientRegistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              '재료 등록 화면',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '추후 구현 예정',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
