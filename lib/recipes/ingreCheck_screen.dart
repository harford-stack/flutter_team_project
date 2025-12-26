// 인식된(선택된) 재료 확인 화면

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_team_project/recipes/ingreEdit_screen.dart';
import 'package:flutter_team_project/recipes/shakeCheck_widget.dart';

class IngrecheckScreen extends StatefulWidget {
  const IngrecheckScreen({super.key});

  @override
  State<IngrecheckScreen> createState() => _IngrecheckScreenState();
}

class _IngrecheckScreenState extends State<IngrecheckScreen> {

  List<String> detectedIngredients = []; // 인식한 재료 이름들
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 200,
              color: Colors.grey[300],
            ),
            SizedBox(height: 30), // 간격 두기
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("인식된 재료 ",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${detectedIngredients.length}개",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    // 색상은 나중에 색코드 파일 따로 만들어서 지정하면 끌고올 예정
                  ),
                ),
              ],
            ),

            // 인식된 재료명 나열할거임!(위젯 임포트 예정)

            SizedBox(height: 30), // 간격 두기
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: (){ // 쉐킷 팝업창 띄우기
                      showDialog(
                        context: context,
                        barrierDismissible: false, // 바깥 터치로 닫히지 않게
                        builder: (_) => const ShakeCheck(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 60),
                    ),
                    child: Text("이대로\n레시피 추천받기", textAlign: TextAlign.center)
                ),
                SizedBox(width: 25), // 간격 두기
                ElevatedButton(
                    onPressed: (){
                      Navigator.push(
                          context,
                          MaterialPageRoute( 
                              builder: (_) => IngreeditScreen() 
                            // 재료 편집 화면으로 이동
                          )
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 60),
                    ),
                    child: Text("재료 편집하기")
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
