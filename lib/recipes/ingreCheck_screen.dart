// 인식된(선택된) 재료 확인 화면

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_team_project/recipes/ingreEdit_screen.dart';
import 'package:flutter_team_project/recipes/shakeCheck_widget.dart';
import 'package:flutter_team_project/recipes/ingreTextList_widget.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../auth/home_screen.dart';
import '../auth/login_screen.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_drawer.dart';
import '../common/custom_footer.dart';
import '../providers/temp_ingre_provider.dart';

class IngrecheckScreen extends StatefulWidget {
  const IngrecheckScreen({super.key});

  @override
  State<IngrecheckScreen> createState() => _IngrecheckScreenState();
}

class _IngrecheckScreenState extends State<IngrecheckScreen> {
  int _currentIndex = 0;

  // ★ 풋터
  void _onFooterTap(int index, AuthProvider authProvider) {
    // 로그인이 필요한 메뉴이므로 로그인 여부 체크 (재료 등록, 커뮤니티)
    if (index == 1 || index == 2) {
      if (!authProvider.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요한 메뉴입니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        // 로그인 화면으로 이동
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }
    }

    // 풋터의 3개 메뉴 클릭시, 각 화면 이동하면서 ★ 레시피 세션종료! (임시저장 재료 삭제)
    if (index == 0 || index == 1 || index == 2) {
      context.read<TempIngredientProvider>().clearAll();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeScreen(initialIndex: index),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // provider에서 임시 재료목록 가져오기
    final ingredients = context.watch<TempIngredientProvider>().ingredients;

    // 앱 전체에 공유되고 있는 인증 데이터를 이 화면(context)으로 가져와서 사용하겠다
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // 배경색 지정
      // SafeArea를 사용하여 기기 상단바/하단바 간섭 방지
      appBar: const CustomAppBar(
        appName: "인식 결과",
      ),
      drawer: const CustomDrawer(),
      body: Container(
        color: AppColors.backgroundColor,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView( // 전체 화면 스크롤
                child: Column(
                  children: [
                    // 위 박스: 이미지와 재료 목록
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0), // 재료 리스트 영역만 좌우 패딩 줄임
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Text("인식 결과", style: TextStyle(fontSize: 25, color : AppColors.textDark),),
                            Image.asset("assets/recipe_ingreChk_result.png", width: 300,),
                            SizedBox(height: 20), // 간격 두기

                            // 인식된 사진 담기는 곳
                            Container(
                              width: 300,
                              height: 200,
                              color: Color(0xFFEEEEEE),
                              alignment: Alignment.center, // 텍스트 중앙 정렬
                              child: context.watch<TempIngredientProvider>().photos.isNotEmpty
                                  ? Image.file(
                                context.watch<TempIngredientProvider>().photos.last,
                                fit: BoxFit.cover,
                                width: double.infinity, // 컨테이너 너비에 맞춤
                                height: double.infinity,
                              )
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/image_no_picture.png',
                                    width: 120,
                                    height: 120,
                                  ),
                                  //SizedBox(height: 5), // 이미지와 텍스트 사이 간격
                                  Text(
                                    '사진 없이 목록에서만 체크된\n재료 내용입니다.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 20, color: AppColors.textDark),
                                  ),
                                ],
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
                                      color : AppColors.textDark
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
                            SizedBox(height: 15), // 간격 두기

                            // 인식된 재료명 나열할거임!
                            // 높이 제한 제거, 전체 스크롤 가능하도록
                            // 좌우 여백을 줄여서 가로로 3개씩 표시되도록
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0), // 최소 여백만 유지 (Container의 24 패딩 대신 8만 사용)
                              child: IngreTextListWidget(detectedIngredients: ingredients),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 위 박스와 아래 박스 사이 간격
                    const SizedBox(height: 20),
                    // 아래 박스: 버튼과 텍스트
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
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
                                        backgroundColor: AppColors.primaryColor,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: const Text(
                                          "이대로\n레시피 추천받기",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textWhite,
                                          )
                                      )
                                  ),
                                ),
                                SizedBox(width: 12), // 간격 두기

                                Expanded(
                                  child: ElevatedButton(
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
                                        backgroundColor: AppColors.primaryColor,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: const Text(
                                          "재료편집 또는\n키워드 넣기",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textWhite,
                                          )
                                      )
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20), // 간격 두기
                            Text(
                                "재료를 냉장고에 넣어두고 싶다면, 오른쪽 버튼 클릭!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 15
                                )
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // 하단 여백
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16), // 하단 여백
            ],
          ),
        ),
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTap: (index) => _onFooterTap(index, authProvider),
      ),
    );
  }
}