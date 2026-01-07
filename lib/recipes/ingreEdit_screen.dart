// 재료 직접 편집하기 화면
// 재료 목록은 재료 위젯에서 불러오기 (ingreTextList_widget.dart)
// '재료 추가' 버튼 팝업은 그냥 따로 안 빼고 여기서 통합 구현함! (너무 복잡해지면 따로 파일 뺄 예정)

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_team_project/recipes/shakeCheck_widget.dart';
import 'package:flutter_team_project/recipes/ingreTextList_widget.dart';
import 'package:flutter_team_project/recipes/shakeDialog_widget.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../auth/home_screen.dart';
import '../auth/login_screen.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import '../common/custom_drawer.dart';
import '../common/custom_footer.dart';
import '../community/screens/community_list_screen.dart';
import '../ingredients/select_screen.dart';
import '../ingredients/service_ingredientFirestore.dart';
import '../ingredients/user_refrigerator.dart';
import '../ingredients/user_ingredient_regist.dart';
import '../providers/temp_ingre_provider.dart';
import '../community/screens/community_list_screen.dart';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider; // AuthProvider만 숨기기
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_provider.dart'; // 이제 이 파일의 AuthProvider만 인식됨
import 'package:flutter_team_project/recipes/shakeDialog_widget.dart';

class IngreeditScreen extends StatefulWidget {
  const IngreeditScreen({super.key});

  @override
  State<IngreeditScreen> createState() => _IngreeditScreenState();
}

class _IngreeditScreenState extends State<IngreeditScreen> {
  // 테마 목록 (음식을 먹는 분위기나 목적)
  final List<String> _themes = [
    '다이어트 / 건강식',
    '든든한 한끼',
    '아이 간식',
    '특별한 날 / 파티',
    '간단한 요리',
    '따뜻한 국물요리',
    '바삭한 식감',
    '달콤한 디저트',
    '시원한 음식',
    '반찬 만들기',
    '야식 / 간식',
  ];

  final List<String> _selectedThemes = []; // 선택된 테마들

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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

    // 풋터의 3개 메뉴 클릭시 ★레시피 세션종료(임시저장 재료 삭제) &
    if (index == 0 || index == 1 || index == 2) {
      context.read<TempIngredientProvider>().clearAll();
    }

    // 각 화면 이동하기! 여기서 아래 나오는 Widget은 새로운 위젯을 만드는 게 아니라
    // 커뮤니티 탭은 바로 CommunityListScreen으로 이동
    if (index == 2) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const CommunityListScreen(showAppBarAndFooter: true),
        ),
            (route) => false,
      );
      return;
    }

    // "내 냉장고"는 독립 화면으로 이동
    if (index == 1) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const UserRefrigerator(),
        ),
            (route) => false,
      );
      return;
    }

    // 홈 화면으로 이동
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
      appBar: const CustomAppBar(
        appName: "재료 편집",
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
                    // 위 박스: 재료 추가 버튼과 이미지
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Text("현재 재료 목록", style: TextStyle(fontSize: 20, color : AppColors.textDark),),
                            Image.asset("assets/recipe_now.png", width: 300), // 이미지 크기 소폭 축소
                            SizedBox(height: 10),

                            // ★ 재료 목록 영역: 높이 제한 제거, 전체 스크롤 가능하도록
                            // 좌우 여백을 줄여서 가로로 3개씩 표시되도록
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0), // 최소 여백만 유지 (Container의 24 패딩 대신 8만 사용)
                              child: ingredients.isEmpty
                                  ? Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text("현재 선택된 재료가 없습니다."),
                              )
                                  : IngreTextListWidget(detectedIngredients: ingredients),
                            ),

                            const SizedBox(height: 20), // 재료 목록과 버튼 사이 간격

                            // -------- 오른쪽 하단 '재료 추가' 버튼 및 팝업 (이동됨) ----------
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end, // 버튼만 오른쪽
                              children: [
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
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
                                                        MaterialPageRoute(
                                                          builder: (context) => const UserRefrigerator(isForRecommendation: true),
                                                        ),
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
                                                  onPressed: () async {
                                                    Navigator.pop(context);
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        // ★ ingreEdit에서 진입 → 최초 진입 아님 + 직접 입력 허용
                                                        // 레시피 추천용이므로 saveToRefrigerator: false (카테고리 선택 불필요)
                                                        builder: (context) => const SelectScreen(
                                                          isInitialFlow: false,
                                                          enableCustomInput: true,
                                                          saveToRefrigerator: false,
                                                        ),
                                                      ),
                                                    );
                                                    // SelectScreen에서 이미 알림을 표시했으므로 여기서는 표시하지 않음
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
                                    child: const Text(
                                        "추가",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textWhite,
                                        )
                                    )
                                ),
                              ],
                            ),
                            // -------- 오른쪽 하단 '재료 추가' 버튼 및 팝업 (끝) ----------
                          ],
                        ),
                      ),
                    ),
                    // 위 박스와 테마 선택 박스 사이 간격
                    const SizedBox(height: 16),
                    // 테마 선택 영역을 담는 별도 박스
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Text("테마 선택", style: TextStyle(fontSize: 20, color : AppColors.textDark),),
                            Image.asset("assets/recipe_theme.png", width: 285), // 이미지 크기 소폭 축소
                            const SizedBox(height: 15),

                            // 테마 선택 버튼들 (Wrap으로 배치)
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: _themes.map((theme) {
                                final isSelected = _selectedThemes.contains(theme);
                                return ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedThemes.remove(theme);
                                      } else {
                                        _selectedThemes.add(theme);
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? AppColors.primaryColor
                                        : Colors.white,
                                    foregroundColor: isSelected
                                        ? AppColors.textWhite
                                        : AppColors.textDark,
                                    // --- 테두리 설정 추가 ---
                                    side: BorderSide(
                                      color: AppColors.secondaryColor, // 테두리 색상을 AppColors로 설정
                                      width: 1.0, // 테두리 두께
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: isSelected ? 2 : 0,
                                  ),
                                  child: Text(
                                    theme,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 35), // 간격 소폭 축소

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                      onPressed: (){
                                        FocusScope.of(context).unfocus(); // 키보드 숨기기
                                        if (ingredients.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('인식된 재료는 최소 1개 이상이어야 합니다.'),
                                              duration: Duration(seconds: 2),
                                              behavior: SnackBarBehavior.fixed,
                                            ),
                                          );
                                        } else {
                                          // ★ Provider에 선택된 테마들을 저장 (쉼표로 구분된 문자열로)
                                          final themesString = _selectedThemes.join(', ');
                                          context.read<TempIngredientProvider>().setKeyword(themesString);

                                          // ★ 기존 ShakeCheck 대신 ShakeDialog 호출 (깜빡임 방지용 통합 관리자)
                                          showFadeDialog(
                                            context: context,
                                            child: const ShakeDialog(),
                                          );

                                          // 기존 : 쉐킷하시겠습니까? 팝업 띄우기 주석처리
                                          // showDialog(
                                          //   context: context,
                                          //   barrierDismissible: false,
                                          //   builder: (_) => ShakeCheck(),
                                          // );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        minimumSize: const Size(0, 90), // 최소 높이 설정
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: const Text(
                                          "레시피 추천받기",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textWhite,
                                          )
                                      )
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
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
                                        backgroundColor: AppColors.primaryColor,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        minimumSize: const Size(0, 90), // 최소 높이 설정 (다른 버튼과 동일)
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: const Text(
                                          "내 냉장고로\n재료 등록하기",
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
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // 하단 여백
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: _currentIndex,
        onTap: (index) => _onFooterTap(index, authProvider),
      ),
    );
  }

  // ★ 빨간줄 방지를 위해 파일 내부에 함수를 직접 포함시킵니다.
  Future<void> showFadeDialog({required BuildContext context, required Widget child}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => child,
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }
}