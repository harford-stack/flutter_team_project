// 재료 직접 편집하기 화면
// 재료 목록은 재료 위젯에서 불러오기 (ingreTextList_widget.dart)
// '재료 추가' 버튼 팝업은 그냥 따로 안 빼고 여기서 통합 구현함! (너무 복잡해지면 따로 파일 뺄 예정)

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_team_project/recipes/shakeCheck_widget.dart';
import 'package:flutter_team_project/recipes/ingreTextList_widget.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../common/app_colors.dart';
import '../ingredients/select_screen.dart';
import '../ingredients/user_ingredient.dart';
import '../ingredients/user_ingredient_regist.dart';
import '../providers/temp_ingre_provider.dart';

class IngreeditScreen extends StatefulWidget {
  const IngreeditScreen({super.key});

  @override
  State<IngreeditScreen> createState() => _IngreeditScreenState();
}

class _IngreeditScreenState extends State<IngreeditScreen> {

  final TextEditingController _keywordController = TextEditingController(); // 키워드 입력 컨트롤러

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // provider에서 임시 재료목록 가져오기
    final ingredients = context.watch<TempIngredientProvider>().ingredients;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // 배경색 지정
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // 기본은 가운데
            children: [
              SizedBox(height: 30),

              // -------- 오른쪽 상단 '재료 추가' 버튼 및 팝업 (시작) ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // 버튼만 오른쪽
                children: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor
                      ),
                      onPressed: (){
                        // 키보드 숨기기
                        FocusScope.of(context).unfocus();

                        // 로그인 여부 확인 위해
                        final authProvider = context.read<AuthProvider>();

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                "재료 추가 방법 선택",
                                style: TextStyle(fontSize: 20, color : AppColors.textDark),
                                textAlign: TextAlign.center,
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);

                                      if (authProvider.isAuthenticated) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => UserIngredientRegist()),
                                        );
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => LoginScreen()),
                                        );
                                      }
                                    },
                                    child: Text(
                                        "내 냉장고에서 선택하기",
                                        style: TextStyle(
                                            color: AppColors.primaryColor,
                                            fontSize: 17
                                        )
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => SelectScreen()),
                                      );
                                    },
                                    child: Text(
                                        "재료 목록에서 선택하기",
                                        style: TextStyle(
                                            color: AppColors.primaryColor,
                                            fontSize: 17
                                        )
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Text(
                          "재료 추가",
                          style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16
                          )
                      )
                  ),
                ],
              ),
              SizedBox(height: 20),
              // -------- 오른쪽 상단 '재료 추가' 버튼 및 팝업 (끝) ----------

              Text("현재 재료 목록", style: TextStyle(fontSize: 20, color : AppColors.textDark),),
              SizedBox(height: 40),

              ingredients.isEmpty
                  ? Text("현재 선택된 재료가 없습니다.")
                  : IngreTextListWidget(detectedIngredients: ingredients),
              SizedBox(height: 80),

              Text("키워드 선택(직접 입력)", style: TextStyle(fontSize: 20, color : AppColors.textDark),),
              SizedBox(height: 10),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _keywordController,
                  decoration: InputDecoration(
                    hintText: "ex)비오는 날, 해장 등",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),

              SizedBox(height: 50),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  ElevatedButton(
                      onPressed: (){
                        FocusScope.of(context).unfocus(); // 키보드 숨기기
                        if (ingredients.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('인식된 재료는 최소 1개 이상이어야 합니다.'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          // ★ Provider에 현재 입력된 "키워드" 저장 후
                          context.read<TempIngredientProvider>().setKeyword(_keywordController.text.trim());

                          // 쉐킷하시겠습니까? 팝업 띄우기
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => ShakeCheck(),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 60),
                        backgroundColor: AppColors.primaryColor
                      ),
                      child: Text(
                          "레시피 추천받기",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 15
                          )
                      )
                  ),
                  SizedBox(width: 25),
                  ElevatedButton(
                      onPressed: (){
                        FocusScope.of(context).unfocus(); // 키보드 숨기기
                        final authProvider = context.read<AuthProvider>();

                        if (authProvider.isAuthenticated) {
                          Navigator.pushNamed(context, "");
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 60),
                        backgroundColor: AppColors.primaryColor
                      ),
                      child: Text(
                          "내 냉장고로\n재료 등록하기",
                          style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 15
                          )
                      )
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
