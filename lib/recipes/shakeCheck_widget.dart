// 쉐킷하시겠어요? 팝업 (위젯)
// '지금 쉐-킷!' 버튼 누르는 순간
// Provider에서 재료를 가져와 AI 호출을 시작하고,
// 그 Future(작업)를 다음 화면으로 넘겨주는 화면

import 'package:flutter/material.dart';
// import 'package:flutter_team_project/recipes/shaking_widget.dart'; // 부모에서 제어하므로 필요 시 유지

import 'package:provider/provider.dart';
import 'package:flutter_team_project/providers/temp_ingre_provider.dart';
import 'package:flutter_team_project/recipes/recipe_ai_service.dart';
import 'package:flutter_team_project/recipes/recipe_model.dart';

import '../common/app_colors.dart';

class ShakeCheck extends StatefulWidget {
  final VoidCallback onStart; // ★ 부모 위젯으로부터 시작 명령을 받기 위해 추가
  const ShakeCheck({super.key, required this.onStart}); // 생성자 수정

  @override
  State<ShakeCheck> createState() => _ShakeCheckState();
}

class _ShakeCheckState extends State<ShakeCheck> {
  // late final Future<List<RecipeModel>> _recipeFuture; // ★ 이제 부모(ShakeDialog)에서 관리하므로 주석 처리하거나 제거 가능

  @override
  void initState() {
    super.initState();

    // 1. Provider에서 현재 담긴 재료 및 키워드 가져오기
    // (이 로직은 부모 위젯의 _handleStartShaking으로 옮겨졌으므로 여기선 실행하지 않아도 됨)
    /*
    final provider = context.read<TempIngredientProvider>();
    final ingredients = provider.ingredients;
    final keyword = provider.keyword;

    // 2. AI 호출 시작 (딱 한 번만 실행됨)
    _recipeFuture = generateRecipes(
      ingredients: ingredients,
      keyword: keyword.isNotEmpty ? keyword : null,
    );
    */
  }

  @override
  Widget build(BuildContext context) {
    // 부모(ShakeDialog)가 이미 Center, Material, Container(흰배경)를 가지고 있으므로
    // 여기서는 내용물인 Stack/Column만 반환하여 중복 레이아웃을 방지합니다.
    return Stack(
        clipBehavior: Clip.none, // X 버튼이 팝업 영역 끝에 걸쳐도 잘리지 않게 설정
        children: [
          // 중앙 내용물 영역
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ★ 사진 분석 결과, 2번 위젯과 높이를 맞추기 위해 상단 여백을 0으로 조정하거나
                // ★ 2번 위젯의 Column 시작점과 완전히 동일하게 맞춥니다.
                const SizedBox(height: 0),

                // 이미지 영역 (2번 위젯과 100% 동일한 SizedBox 크기 사용)
                SizedBox(
                  width: 170,
                  height: 170,
                  child: Image.asset(
                    "assets/shaking_move.gif",
                    fit: BoxFit.contain, // 이미지 비율 보존
                  ),
                ),

                // 2번과 동일한 간격 (이미지 하단 텍스트 시작 위치)
                const SizedBox(height: 15),

                // 포인트 문구
                Text(
                  "준비된 재료들을\n시원하게 섞어볼까요?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "버튼을 누르고 휴대폰을 흔들어주세요!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                // ★ 2번 위젯의 로딩바 영역 높이만큼을 확보하여 버튼 위치를 아래로 밀어줌
                // ★ 이 여백이 부족하면 버튼이 위로 올라와 이미지가 밀려 보일 수 있습니다.
                const SizedBox(height: 95),

                // '지금 쉐-킷!' 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () { // 쉐킷 화면 흔들기로 이동
                      // ★ 기존의 Navigator.pop 및 showFadeDialog 로직은 부모 위젯이 처리합니다.
                      // ★ 여기서는 부모가 넘겨준 함수만 실행하면 화면이 전환됩니다.
                      widget.onStart();
                    },
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: AppColors.primaryColor
                    ),
                    child: const Text(
                      '지금 쉐-킷 !',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 오른쪽 상단 X 버튼 (2번 위젯과 위치 및 스타일 완전 일치)
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
                  color: Colors.black, // 2번 위젯과 색상 통일
                ),
              ),
            ),
          ),
        ]
    );
  }
}

// 팝업 넘어갈 때 페이드아웃 처리하는 함수 (기존 코드 유지)
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