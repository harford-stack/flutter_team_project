// 쉐킷하시겠어요? 팝업 (위젯)
// '지금 쉐-킷!' 버튼 누르는 순간 
// Provider에서 재료를 가져와 AI 호출을 시작하고, 
// 그 Future(작업)를 다음 화면으로 넘겨주는 화면

import 'package:flutter/material.dart';
import 'package:flutter_team_project/recipes/recipe_ai_service.dart';
import 'package:flutter_team_project/recipes/shaking_widget.dart';

import 'package:provider/provider.dart';
import 'package:flutter_team_project/providers/temp_ingre_provider.dart';
import 'package:flutter_team_project/recipes/recipe_ai_service.dart';

class ShakeCheck extends StatelessWidget {
  const ShakeCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent, // 다이얼로그 배경 투명
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // 이미지 영역
                  Expanded(
                    flex: 8,
                    child: Image.asset(
                      "assets/shake_chk.png",
                      fit: BoxFit.contain, // 세로 긴 이미지 안전
                    ),
                  ),

                  const SizedBox(height: 20),

                  // '지금 쉐-킷!' 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async { // 쉐킷 화면 흔들기로 이동

                        // 1. Provider에서 현재 담긴 재료 가져오기
                        final ingredients = Provider.of<TempIngredientProvider>(context, listen: false).ingredients;

                        // 2. AI 호출 시작 (await를 붙이지 않고 Future 객체만 생성하여 넘김)
                        final recipeFuture = generateRecipes(ingredients: ingredients);

                        Navigator.of(context).pop();
                        // 그  팝업 닫기 (겹치면 부자연스럽)

                        await Future.delayed(const Duration(milliseconds: 100));
                        // 딜레이 줘서 닫힘 애니메이션과 겹치지 않게 함

                        showFadeDialog(
                          context: context,
                          // child: const ShakingWidget(), (기존 내용 주석처리)

                          // ShakingWidget에 진행 중인 작업을 전달
                          child: ShakingWidget(recipeTask: recipeFuture),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '지금 쉐-킷 !',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 오른쪽 상단 X 버튼 (팝업 닫기)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'X',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }
}

// 팝업 넘어갈 때 페이드아웃 처리하는 함수
Future<void> showFadeDialog({
  required BuildContext context,
  required Widget child,
}) {
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
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
          ),
          child: child,
        ),
      );
    },
  );
}