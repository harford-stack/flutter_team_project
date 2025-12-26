// 재료 직접 편집하기 화면
// 재료 목록은 재료 위젯에서 불러오기 (ingreTextList_widget.dart)
// '재료 추가' 버튼 팝업은 그냥 따로 안 빼고 여기서 통합 구현함! (너무 복잡해지면 따로 파일 뺄 예정)

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_team_project/recipes/shakeCheck_widget.dart';

class IngreeditScreen extends StatefulWidget {
  const IngreeditScreen({super.key});

  @override
  State<IngreeditScreen> createState() => _IngreeditScreenState();
}

class _IngreeditScreenState extends State<IngreeditScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // 기본은 가운데
            children: [
              SizedBox(height: 30),
              // 버튼 위에 공간 추가 (어차피 앱바 들어오면 내려갈듯?)

              // -------- 오른쪽 상단 '재료 추가' 버튼 및 팝업 (시작) ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // 버튼만 오른쪽
                children: [
                  ElevatedButton(
                      onPressed: (){
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                "재료 추가 방법 선택",
                                style: TextStyle(fontSize: 20),
                                textAlign: TextAlign.center, // 가운데 정렬
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min, // 컬럼 최소 크기
                                children: [
                                  TextButton(
                                    onPressed: () {
                                        Navigator.pop(context); // 다이얼로그 닫기

                                        // ★ 만약 로그인 상태 관리용 위젯이 만들어졌다면, 임포트해서 작성 예정!
                                        if (1==1) {
                                          // 로그인 상태면 내 냉장고 화면 이동
                                          Navigator.pushNamed(context, ""); 
                                        } else {
                                          // 비로그인 상태면 로그인 화면으로 이동
                                          Navigator.pushNamed(context, ""); 
                                        }
                                      },
                                    child: Text("내 냉장고에서 선택하기"),
                                  ),

                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, " "); // 재료목록 화면으로 이동 예정
                                    },
                                    child: Text("재료 목록에서 선택하기"),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Text("재료 추가")
                  ),
                ],
              ),
              SizedBox(height: 20),
              // -------- 오른쪽 상단 '재료 추가' 버튼 및 팝업 (끝) ----------


              // 인식된(선택된) 재료 목록 (위젯에서 가져올 예정)
              Text("현재 재료 목록", style: TextStyle(fontSize: 20),),
              SizedBox(height: 40),
              
              // 키워드 입력받기
              Text("키워드 선택(직접 입력)", style: TextStyle(fontSize: 20),),
              SizedBox(height: 10),
              SizedBox(
                width: 300,
                child: TextField(
                  // 차후 컨트롤러도 연결하기
                  decoration: InputDecoration(
                    // labelText: " ",
                    // prefixIcon: Icon(Icons.email),
                    hintText: "ex)비오는 날, 해장 등",
                    border: OutlineInputBorder(),
                    filled: true, // 안쪽에 색 채우기 (디폴트 : false)
                    fillColor: Colors.grey[200], // 위 값이 true여야만 가능
                    // enabled: false // 특정조건시 막아둘 수 있음
                  ),
                ),
              ),

              SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  // 레시피 추천받기 버튼
                  ElevatedButton(
                      onPressed: (){
                        showDialog(
                          context: context,
                          barrierDismissible: false, // 바깥 터치로 닫히지 않게
                          builder: (_) => const ShakeCheck(), // 지금 쉐킷하기 팝업
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 60),
                      ),
                      child: Text("레시피 추천받기", textAlign: TextAlign.center)
                  ),
                  SizedBox(width: 25), // 간격 두기
                  ElevatedButton(
                      onPressed: (){ },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 60),
                      ),
                      child: Text("내 냉장고로\n재료 등록하기")
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}
