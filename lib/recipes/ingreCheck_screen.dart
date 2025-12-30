// 인식된(선택된) 재료 확인 화면

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_team_project/recipes/ingreEdit_screen.dart';
import 'package:flutter_team_project/recipes/shakeCheck_widget.dart';
import 'package:flutter_team_project/recipes/ingreTextList_widget.dart';
import 'package:provider/provider.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_footer.dart';
import '../providers/temp_ingre_provider.dart';

class IngrecheckScreen extends StatefulWidget {
  const IngrecheckScreen({super.key});

  @override
  State<IngrecheckScreen> createState() => _IngrecheckScreenState();
}

class _IngrecheckScreenState extends State<IngrecheckScreen> {

  @override
  Widget build(BuildContext context) {
    // provider에서 임시 재료목록 가져오기
    final ingredients = context.watch<TempIngredientProvider>().ingredients;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("인식 결과", style: TextStyle(fontSize: 25),),
            SizedBox(height: 30), // 간격 두기
            
            // 인식된 사진 담기는 곳
            Container(
              width: 300,
              height: 200,
              color: Colors.grey[300],
              alignment: Alignment.center, // 텍스트 중앙 정렬
              child: context.watch<TempIngredientProvider>().photos.isNotEmpty
                  ? Image.file(
                context.watch<TempIngredientProvider>().photos.last,
                fit: BoxFit.cover,
              )
                  : Text(
                '사진 없이 목록에서만 체크된\n재료 내용입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.black54),
              ),
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
                  "${ingredients.length}개",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    // 색상은 나중에 색코드 파일 따로 만들어서 지정하면 끌고올 예정
                  ),
                ),
              ],
            ),
            SizedBox(height: 30), // 간격 두기

            // 인식된 재료명 나열할거임!
            IngreTextListWidget(detectedIngredients: ingredients),

            SizedBox(height: 30), // 간격 두기
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: (){ // 쉐킷 팝업창 띄우기
                      // 재료가 0개인지 확인
                      if (ingredients.isEmpty) {
                        // 0개라면 안내 스낵바 띄우기
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('인식된 재료는 최소 1개 이상이어야 합니다.'),
                            duration: Duration(seconds: 2), // 2초 동안 표시
                            behavior: SnackBarBehavior.floating, // 떠 있는 스타일 (선택사항)
                          ),
                        );
                    } else { // 재료가 1개 이상일 시
                        showDialog(
                          context: context,
                          barrierDismissible: false, // 바깥 터치로 닫히지 않게
                          builder: (_) => ShakeCheck(),
                        );
                      }
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
