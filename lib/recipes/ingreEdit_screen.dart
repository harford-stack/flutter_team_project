// 재료 직접 편집하기 화면
// 재료 목록은 재료 위젯에서 불러오기 (ingreTextList_widget.dart)
// '재료 추가' 버튼 팝업은 그냥 따로 안 빼고 여기서 통합 구현함! (너무 복잡해지면 따로 파일 뺄 예정)

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import '../ingredients/select_screen.dart';
import '../ingredients/service_ingredientFirestore.dart';
import '../ingredients/user_refrigerator.dart';
import '../ingredients/user_ingredient_regist.dart';
import '../providers/temp_ingre_provider.dart';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider; // AuthProvider만 숨기기
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_provider.dart'; // 이제 이 파일의 AuthProvider만 인식됨

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

  // 선택된(인식된) 재료들을 '내 냉장고에 추가'하는 기능 (로그인 사용자만) -------------
  Future<void> _saveToUserRefrigerator() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final provider = context.read<TempIngredientProvider>();
    final ingredientsToSave = provider.ingredients; // 현재 화면에 표시된 재료들

    if (ingredientsToSave.isEmpty) return;

    try {
      // 1. 기존 사용자의 재료 목록 가져오기 (중복 체크용)
      final userIngreRef = firestore.collection('users').doc(user.uid).collection('user-ingredients');
      final existingSnapshot = await userIngreRef.get();
      final existingNames = existingSnapshot.docs.map((doc) => doc['name'] as String).toSet();

      // 2. 전체 재료 DB에서 카테고리 정보를 매칭하기 위한 준비
      // (service_getCategoryIngre.dart나 service_ingredientFirestore.dart의 기능을 활용)
      // 여기서는 모든 카테고리를 돌며 해당 재료가 어디 속하는지 찾습니다.
      final IngredientService service = IngredientService();
      List<String> categories = await service.getCategories();

      Map<String, String> nameToCategoryMap = {};

      // 전체 카테고리를 순회하며 이름:카테고리 맵 생성 (효율을 위해)
      for (String category in categories) {
        List<String> items = await service.getIngredients(category);
        for (String item in items) {
          if (ingredientsToSave.contains(item)) {
            nameToCategoryMap[item] = category;
          }
        }
      }

      int addCount = 0;

      // 3. 저장 실행
      for (String name in ingredientsToSave) {
        // 중복 검사
        if (existingNames.contains(name)) {
          print("$name 은(는) 이미 냉장고에 있습니다.");
          continue;
        }

        // 카테고리 찾기 (기본값 '기타' 혹은 매칭된 값)
        String category = nameToCategoryMap[name] ?? "기타";

        await userIngreRef.add({
          'name': name,
          'category': category,
          'addedAt': FieldValue.serverTimestamp(),
        });
        addCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(addCount > 0 ? '$addCount개의 재료가 냉장고에 등록되었습니다.' : '이미 모두 등록된 재료입니다.'))
        );
      }
    } catch (e) {
      print("저장 중 오류 발생: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장 중 오류가 발생했습니다.'))
        );
      }
    }
  }
  // ------------------------------------------------------------

  // ★ 풋터

  int _currentIndex = 0;

  void _onFooterTap(int index, AuthProvider authProvider) {
    // 로그인이 필요한 메뉴이므로 로그인 여부 체크 (재료 등록, 커뮤니티)
    if (index == 1 || index == 2) {
      if (!authProvider.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 필요한 메뉴입니다.'),
            backgroundColor: AppColors.primaryColor,
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

  //------------------------풋터 내용 끝------------------------------

  @override
  Widget build(BuildContext context) {

    // provider에서 임시 재료목록 가져오기
    final ingredients = context.watch<TempIngredientProvider>().ingredients;

    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor, // 배경색 지정
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView( // 전체 화면 키보드 대응을 위한 스크롤 허용
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // 기본은 가운데
            children: [
              SizedBox(height: 10), // 상단 여백 소폭 축소

              // -------- 오른쪽 상단 '재료 추가' 버튼 및 팝업 (시작) ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // 버튼만 오른쪽
                children: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
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
                                          MaterialPageRoute(builder: (context) => UserRefrigerator()),
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
                                        MaterialPageRoute(
                                          // ★ ingreEdit에서 진입 → 최초 진입 아님
                                          builder: (context) => const SelectScreen(isInitialFlow: false),
                                        ),
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
                              fontSize: 15
                          )
                      )
                  ),
                ],
              ),
              SizedBox(height: 20),
              // -------- 오른쪽 상단 '재료 추가' 버튼 및 팝업 (끝) ----------

              // Text("현재 재료 목록", style: TextStyle(fontSize: 20, color : AppColors.textDark),),
              Image.asset("assets/recipe_now.png", width: 250), // 이미지 크기 소폭 축소
              SizedBox(height: 10),

              // ★ 재료 목록 영역: 최대 높이(MaxHeight) 및 가로 폭(SizedBox) 제한
              SizedBox(
                width: 305, // 하단 버튼 2개의 합(140+140) + 사이 간격(25)에 맞춘 폭
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200, // 약 3~4줄 분량
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: ingredients.isEmpty
                            ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text("현재 선택된 재료가 없습니다."),
                        )
                            : IngreTextListWidget(detectedIngredients: ingredients),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 55),

              // Text("키워드 선택(직접 입력)", style: TextStyle(fontSize: 20, color : AppColors.textDark),),
              Image.asset("assets/recipe_keyword.png", width: 250), // 이미지 크기 소폭 축소
              SizedBox(height: 10),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _keywordController,
                  decoration: InputDecoration(
                    hintText: "ex) 다이어트, 비오는 날, 해장 등",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[200],
                    isDense: true, // 입력창 높이 최적화
                  ),
                ),
              ),

              SizedBox(height: 40), // 간격 소폭 축소

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
                      onPressed: () async {
                        FocusScope.of(context).unfocus(); // 키보드 숨기기
                        final authProvider = context.read<AuthProvider>();

                        if (authProvider.isAuthenticated) {
                          // 로그인한 경우, 로딩 다이얼로그 등을 띄워주기(선택사항)
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );
                          await _saveToUserRefrigerator(); // db에 냉장고 재료 저장
                          if (mounted) Navigator.pop(context); // 로딩 닫기

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
              SizedBox(height: 20),
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