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
      body: SafeArea(
        child: Padding(
          // 화면 전체에 상하좌우 고정 패딩 부여 (Column을 직접 감싸도록 조정)
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              // Flexible과 SingleChildScrollView로 중간 영역 스크롤 처리
              // Expanded를 사용하여 남은 공간을 차지하게 하고 이 내부에서만 스크롤이 되도록 함
              Expanded(
                child: SizedBox(
                  width: 300,
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(), // 부드러운 스크롤 효과
                    child: IngreTextListWidget(detectedIngredients: ingredients),
                  ),
                ),
              ),

              SizedBox(height: 20), // 간격 두기
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
                          backgroundColor: AppColors.primaryColor
                      ),
                      child: Text(
                          "이대로\n레시피 추천받기",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 16
                          )
                      )
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
                          backgroundColor: AppColors.primaryColor
                      ),
                      child: Text(
                          "재료편집 또는\n키워드 넣기",
                          textAlign: TextAlign.center, // 텍스트 중앙 정렬 추가
                          style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 17
                          )
                      )
                  ),
                ],
              ),
              SizedBox(height: 20), // 간격 두기
              Text(
                  "재료를 냉장고에 넣어두고 싶다면, 오른쪽 버튼 클릭!",
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15
                  )
              )
            ],
          ),
        ),
      ),
      // 풋터
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTap: (index) => _onFooterTap(index, authProvider),
      ),
    );
  }
}