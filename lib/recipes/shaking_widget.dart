// 쉐킷중(로딩바) 화면 흔들기 팝업 위젯
// 로딩바 100%와 AI 데이터 수신이 모두 완료되었을 때 레시피 목록으로 화면 넘기기

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_team_project/common/app_colors.dart';
import 'package:flutter_team_project/recipes/recipe_model.dart';
import 'package:flutter_team_project/recipes/recipesList_screen.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shake/shake.dart';

class ShakingWidget extends StatefulWidget {
  final Future<List<RecipeModel>> recipeTask; // 추가) AI 작업 수신
  const ShakingWidget({super.key, required this.recipeTask});

  @override
  State<ShakingWidget> createState() => _ShakingWidgetState();
}

class _ShakingWidgetState extends State<ShakingWidget> {
  double _percent = 0.0;
  late ShakeDetector detector;
  bool _hasNavigated = false; // 한 번만 이동하도록 플래그
  List<RecipeModel>? _aiResult; // 데이터 임시 저장(AI 결과를 담아둘 변수 추가)

  @override
  void initState() {
    super.initState();

    // AI 데이터가 도착하면 변수에 담기 & 이동 시도
    widget.recipeTask.then((data) {
      _aiResult = data;
      _navigateToRecipes(); // 혹시 이미 100%면 이동
    }).catchError((e) {
      debugPrint('AI error: $e'); // 에러 시 로그 남기고
      Navigator.pop(context); //  닫기
    });

    // 흔들림 감지 시작
    detector = ShakeDetector.autoStart(
      shakeThresholdGravity: 1.5, // 민감도를 높임 (shake 패키지의 기본 민감도(shakeThresholdGravity = 2.7))
      onPhoneShake: (event) { // ★ 빨간 줄 해결: 매개변수 event 추가

        // 흔들림 감지 시 로딩바 증가
        if (mounted) {
          setState(() {
            _percent += 0.2; // 흔들기마다 20%씩 증가
            if (_percent > 1.0) {
              _percent = 1.0;
              _navigateToRecipes(); // 100% 도달 시 이동
            }
          });
        }
      },
    );
  }

  void _navigateToRecipes({bool force = false}) {
    // 데이터가 아직 없거나(ai응답이 없거나) 이미 이동 중이면 실행하지 않음
    if (!mounted || _hasNavigated) return;

    // 데이터가 아직 없으면 버튼을 눌러도(force) 못 감
    if (_aiResult == null) {
      if (force) { // 버튼 눌렀을 때만 스낵바 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("레시피를 열심히 만드는 중입니다!")),
        );
      }
      return;
    }

    // 흔들기 중일 때는 100%여야 하지만, 버튼(force)을 누르면 즉시 통과
    if (!force && _percent < 1.0) return;

    _hasNavigated = true; // 중복 이동 방지 (여기서 딱 잠금)

    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // 결과를 다음 화면으로 넘겨줌
          builder: (context) => RecipeslistScreen(recipes: _aiResult!),
        ),
      );
    });
  }

  @override
  void dispose() {
    detector.stopListening(); // 메모리 누수 방지
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 부모(ShakeDialog)의 Container 내부에서 보여질 핵심 UI만 반환합니다.
    return Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ★ 1단계(ShakeCheck)와 이미지 높이를 맞추기 위한 상단 여백 (동일하게 10 적용)
                const SizedBox(height: 10),

                // 이미지 영역 (1번 위젯과 크기 및 위치 동일하게 200x200 설정)
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Image.asset(
                    "assets/shaking_move.gif",
                    // 'assets/shaking.png',
                    fit: BoxFit.contain,
                  ),
                ),

                // ★ 1단계와 동일한 간격 적용 (20)
                const SizedBox(height: 20),

                // 텍스트 영역
                Text(
                  "마구 흔들어 보세요!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "오늘의 레시피가\n만들어지는 중이에요",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 25),

                // 로딩바(percent_indicator) 위젯 가져오기
                LinearPercentIndicator(
                  width: MediaQuery.of(context).size.width * 0.65,
                  animation: false, // true로 하면 로딩바가 0부터 계속 초기화
                  lineHeight: 28.0,
                  animationDuration: 300,
                  percent: _percent,
                  center: Text("${(_percent * 100).toStringAsFixed(0)}%"),
                  linearStrokeCap: LinearStrokeCap.roundAll,
                  progressColor: Colors.blue[100], // 공통컬러 넣을 예정
                  barRadius: const Radius.circular(10.0),
                  alignment: MainAxisAlignment.center, // 중앙 정렬 추가
                ),

                // 로딩바와 바닥 사이 정중앙에 배치될 버튼
                // 1단계의 큰 버튼 위치와 밸런스를 맞추기 위해 35 유지
                const SizedBox(height: 35),

                ElevatedButton(
                  onPressed: () => _navigateToRecipes(force: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[700],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // 약간 각진 둥근 형태
                    ),
                  ),
                  child: const Text(
                    "흔들지 않고 결과보기",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10,),
                const Text(
                  "레시피 생성 중으로 몇 초 소요될 수 있습니다.",
                  style: TextStyle(color: AppColors.textDark, fontSize: 12),
                )
              ],
            ),
          ),

          // 오른쪽 상단 닫기 버튼 (아이콘으로 변경)
          Positioned(
            top: -5,   // 아이콘 자체의 여백 때문에 살짝 위로 조정 (위치 완벽 고정)
            right: -5, // 아이콘 자체의 여백 때문에 살짝 오른쪽으로 조정
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                size: 28,
                color: Colors.black54, // 너무 진한 검정보다 세련된 다크그레이
              ),
            ),
          ),
        ]
    );
  }
}