// 쉐킷중(로딩바) 화면 흔들기 팝업 위젯
// 로딩바 100%와 AI 데이터 수신이 모두 완료되었을 때 레시피 목록으로 화면 넘기기

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

    detector = ShakeDetector.autoStart(
      shakeThresholdGravity: 1.5, // 민감도를 높임 (shake 패키지의 기본 민감도(shakeThresholdGravity = 2.7))
      onPhoneShake: (event) {

        // 흔들림 감지 시 로딩바 증가
        setState(() {
          _percent += 0.2; // 흔들기마다 20%씩 증가
          if (_percent > 1.0) {
            _percent = 1.0;
            _navigateToRecipes(); // 100% 도달 시 이동
          }
        });
      },
    );
  }

  void _navigateToRecipes() {
    // 데이터가 아직 없거나(ai응답이 없거나) 이미 이동 중이면 실행하지 않음
    if (!mounted || _hasNavigated) return;
    if (_aiResult == null) return;
    if (_percent < 1.0) return;

    _hasNavigated = true; // 중복 이동 방지
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
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // 이미지 영역
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: Image.asset(
                          'assets/shaking.png',
                          fit: BoxFit.cover,
                        ),
                      ),

                      SizedBox(height: 20),

                      // 텍스트 영역
                      Text(
                        "마구 흔들어 보세요!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 20),

                      Text(
                        "오늘의 레시피가\n만들어지는 중이에요",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 20),

                      // 로딩바(percent_indicator) 위젯 가져오기
                      LinearPercentIndicator(
                        width: MediaQuery.of(context).size.width * 0.65,
                        animation: false, // true로 하면 로딩바가 0부터 계속 초기화
                        lineHeight: 30.0,
                        animationDuration: 300,
                        percent: _percent,
                        center: Text("${(_percent * 100).toStringAsFixed(0)}%"),
                        linearStrokeCap: LinearStrokeCap.roundAll,
                        progressColor: Colors.blue[100], // 공통컬러 넣을 예정
                        barRadius: Radius.circular(10.0),
                      ),

                    ],
                  ),
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
