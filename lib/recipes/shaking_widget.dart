// 쉐킷중(로딩바) 화면 흔들기 팝업

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ShakingWidget extends StatefulWidget {
  const ShakingWidget({super.key});

  @override
  State<ShakingWidget> createState() => _ShakingWidgetState();
}

class _ShakingWidgetState extends State<ShakingWidget> {
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
