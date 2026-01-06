import 'package:flutter/material.dart';
import 'package:flutter_team_project/recipes/shakeCheck_widget.dart';
import 'package:flutter_team_project/recipes/shaking_widget.dart';
import 'package:flutter_team_project/recipes/recipe_ai_service.dart';
import 'package:flutter_team_project/recipes/recipe_model.dart';
import 'package:flutter_team_project/providers/temp_ingre_provider.dart';
import 'package:provider/provider.dart';

class ShakeDialog extends StatefulWidget {
  const ShakeDialog({super.key});

  @override
  State<ShakeDialog> createState() => _ShakeDialogState();
}

class _ShakeDialogState extends State<ShakeDialog> {
  bool _isShaking = false;
  late Future<List<RecipeModel>> _recipeTask;

  void _handleStart() {
    final provider = context.read<TempIngredientProvider>();

    setState(() {
      _recipeTask = generateRecipes(
        ingredients: provider.ingredients,
        keyword: provider.keyword.isNotEmpty ? provider.keyword : null,
      );
      _isShaking = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: 600, // ★ 이미지가 잘리지 않도록 높이만 600으로 수정했습니다.
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          // Stack을 사용하여 X 버튼 위치를 전체 컨테이너 기준으로 고정
          child: Stack(
            children: [
              _isShaking
                  ? ShakingWidget(recipeTask: _recipeTask)
                  : ShakeCheck(onStart: _handleStart),

              // ★ 여기 기존 Text('X') 부분을 아래 아이콘 코드로 교체!
              Positioned(
                top: -5, // IconButton 자체 여백 때문에 조금 더 바깥으로 조정
                right: -5,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    size: 28,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ★ 이 함수가 정의되어 있어야 다른 파일에서 빨간줄이 안 납니다.
Future<void> showFadeDialog({required BuildContext context, required Widget child}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.black.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => child,
    transitionBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
}