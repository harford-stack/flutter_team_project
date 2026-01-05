  // 푸터로 진입하는 재료 등록

  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../common/app_colors.dart';
  import '../common/custom_appbar.dart';
  import '../common/custom_footer.dart';
  import '../common/custom_drawer.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import '../auth/login_screen.dart';
  import '../auth/home_screen.dart';
  import 'dart:async';
  import 'package:flutter_speed_dial/flutter_speed_dial.dart';
  import 'user_ingredient_add.dart';
  import 'user_ingredient_remove.dart';
  import '../providers/temp_ingre_provider.dart';
  import '../auth/auth_provider.dart' as app_auth;
  import '../recipes/ingreCheck_screen.dart';
  import '../community/screens/community_list_screen.dart';


  class UserRefrigerator extends StatefulWidget {
    final bool isForRecommendation; // true: 레시피 추천용, false: 단순 관리용
    final bool fromRecipeOption; // true: recipe_option_screen에서 온 경우, false: 그 외
    
    const UserRefrigerator({
      super.key,
      this.isForRecommendation = false, // 기본값은 관리용
      this.fromRecipeOption = false, // 기본값은 false
    });

    @override
    State<UserRefrigerator> createState() => _UserRefrigeratorState();
  }

  class _UserRefrigeratorState extends State<UserRefrigerator> {
    bool loginFlg = false;
    StreamSubscription<User?>? _authSubscription;
    List<Map<String, String>> userIngredients = [];
    User? user = FirebaseAuth.instance.currentUser;
    List<String> categories = [];
    List<String> ingredientList = [];
    List<String> filteredIngredients = [];
    int selectedCategoryIndex = 0;
    List<Map<String, String>> selectedIngredients = [];
    bool providerFlg = false;
    int _currentIndex = 1; // 내 냉장고 인덱스

    void _onFooterTap(int index, app_auth.AuthProvider authProvider, BuildContext context) {
      // 현재 화면이 "내 냉장고"이므로, "내 냉장고" 클릭 시 아무 동작도 하지 않음
      if (index == 1) {
        return;
      }

      // 로그인이 필요한 메뉴 (커뮤니티)
      if (index == 2) {
        if (!authProvider.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인이 필요한 메뉴입니다.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          return;
        }
        // 커뮤니티 탭은 바로 CommunityListScreen으로 이동
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const CommunityListScreen(showAppBarAndFooter: true),
          ),
          (route) => false,
        );
        return;
      }

      // 홈으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomeScreen(initialIndex: index),
        ),
        (route) => false,
      );
    }

    //선택되었는지 확인
    bool _isSelected(Map<String, String> ingredient) {
      return selectedIngredients.any((item) =>
      item['name'] == ingredient['name'] &&
          item['category'] == ingredient['category']);
    }

    //중복 재료 조회
    List<String> getDuplicateIngredients() {
      final selectedNames =
      userIngredients.map((e) => e['name']!).toSet();

      final providerNames =
      context.read<TempIngredientProvider>().ingredients.toSet();

      final hasProviderNames = providerNames.isNotEmpty;
      if(hasProviderNames){
        print('임시 재료: $providerNames');
      }

      return selectedNames.intersection(providerNames).toList();
    }

    //이미 추가된건지 확인
    bool isAlreadyAdded(String name) {
      return context
          .read<TempIngredientProvider>()
          .ingredients
          .contains(name);
    }

    //사용자 재료 목록 가져오기
    Future<List<Map<String, String>>> _getUserIngredients() async {
      if( user == null){
        return [];
      }

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final DocumentReference userDocRef = firestore.collection('users').doc(user!.uid);
      final ingredientsCollectionRef = userDocRef.collection('user-ingredients');

      final ingredientsSnapshot = await ingredientsCollectionRef.get();

      List<Map<String, String>> tempIngredients = [];

      for ( var doc in ingredientsSnapshot.docs) {
        tempIngredients.add({
          'name': doc['name'] as String,
          'category': doc['category'] as String,
        });
      }

      Set<String> categorySet = tempIngredients
          .map((item) => item['category']!)
          .toSet();

      setState(() {
        userIngredients = tempIngredients;
        categories = categorySet.toList();
        categories.sort();
        categories.remove('기타');
        categories.insert(0, '전체');
        categories.add('기타');
      });

      final duplicates = getDuplicateIngredients();

      final hasUserIngredients = userIngredients.isNotEmpty;
      final hasDuplicates = duplicates.isNotEmpty;

      if(hasUserIngredients){
        print('보유 재료: $userIngredients');
      }

      if(hasDuplicates){
        print('중복 재료: $duplicates');
      }

      // print(userIngredients.length);

      // print(categories);

      return userIngredients;
    }

    //로그인 상태 조회
    void _checkLoginStatus() async {

      // final uid = FirebaseAuth.instance.currentUser!.uid;

      // final doc = await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(uid)
      //     .get();
      //
      // final docInfo = await doc.data();

      if (user != null) {
        print("로그인 상태");
        setState(() {
          loginFlg = true;
        });
      } else {
        print("로그아웃 상태");
        setState(() {
          loginFlg = false;
        });

        // build 이후 실행되도록
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showLoginSnackBar();
        });
      }
    }

    //주기적으로 로그인 여부 확인
    void _listenToAuthChanges() {
      // Firebase Auth 상태 변화 실시간 감지
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user == null) {
          // 로그아웃됨
          print("로그아웃 감지됨");
          if (mounted) {
            setState(() {
              loginFlg = false;
            });
            showLoginSnackBar();
          }
        } else {
          // 로그인됨
          print("로그인 유저: ${user.email}");
          if (mounted) {
            setState(() {
              loginFlg = true;
            });
          }
        }
      });
    }

    //미 로그인 시, 로그인 알림 후, 로그인 화면으로 이동
    void showLoginSnackBar() async {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("로그인이 필요한 기능입니다."),
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }

    //provider에 임시로 재료 등록되었는지 확인
    void _checkProvider() {
      final provider = Provider.of<TempIngredientProvider>(context, listen: false);
      final hasIngredients = provider.ingredients.isNotEmpty;
      if (hasIngredients) {
        print('임시 재료 있음: ${provider.ingredients}');
        // 👉 재료가 있을 때 실행할 로직
        providerFlg = true;
        print('providerFlg: $providerFlg');
      } else {
        print('임시 재료 없음');
        // 👉 재료가 없을 때 실행할 로직
        providerFlg = false;
        print('providerFlg: $providerFlg');
      }
    }

    @override
    void initState() {
      // TODO: implement initState
      super.initState();
      // 레시피 추천용 모드일 때 선택된 재료 초기화
      if (widget.isForRecommendation) {
        selectedIngredients.clear();
        // '내 냉장고 재료로 추천 받기'에서 진입할 때만 Provider도 초기화
        // (재료 편집 화면에서 호출할 때는 기존 재료 유지)
        if (widget.fromRecipeOption) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final provider = Provider.of<TempIngredientProvider>(context, listen: false);
            provider.clear();
          });
        }
      }
      _checkLoginStatus();
      _listenToAuthChanges();
      _getUserIngredients();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkProvider();
      });
    }

    @override
    void dispose() {
      _authSubscription?.cancel(); // 리스너 해제
      // 레시피 추천용 모드일 때 화면을 나갈 때 선택된 재료 초기화
      if (widget.isForRecommendation) {
        selectedIngredients.clear();
      }
      super.dispose();
    }

    // @override
    // Widget build(BuildContext context) {
    //   return Scaffold(
    //     floatingActionButton: SpeedDial(
    //       spaceBetweenChildren: 14,
    //       icon: Icons.menu,
    //       activeIcon: Icons.close,
    //       backgroundColor: AppColors.secondaryColor,
    //       foregroundColor: AppColors.textDark,
    //       children: [
    //         SpeedDialChild(
    //             child: Icon(Icons.remove),
    //             label: '재료 삭제하기',
    //             onTap: (){
    //               Navigator.push(
    //                   context,
    //                   MaterialPageRoute(
    //                       builder: (_)=>UserIngredientRemove()
    //                   )
    //               );
    //             }
    //         )
    //         ,
    //         SpeedDialChild(
    //             child: Icon(Icons.add),
    //             label: '재료 추가하기',
    //             onTap: (){
    //               Navigator.push(
    //                   context,
    //                   MaterialPageRoute(
    //                       builder: (_)=>UserIngredientAdd()
    //                   )
    //               );
    //             }
    //         )
    //       ],
    //     ),
    //     body: Center(
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           const Icon(
    //             Icons.add_circle_outline,
    //             size: 80,
    //             color: Colors.grey,
    //           ),
    //           const SizedBox(height: 20),
    //           Text(
    //             '재료 등록 화면',
    //             style: TextStyle(
    //               fontSize: 20,
    //               color: Colors.grey[600],
    //             ),
    //           ),
    //           // const SizedBox(height: 10),
    //           // Text(
    //           //   '추후 구현 예정',
    //           //   style: TextStyle(
    //           //     fontSize: 14,
    //           //     color: Colors.grey[400],
    //           //   ),
    //           // ),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    @override
    Widget build(BuildContext context) {
      print('build 호출됨: userIngredients.length=${userIngredients.length}');
      final authProvider = Provider.of<app_auth.AuthProvider>(context);
      
      return PopScope(
        onPopInvoked: (didPop) {
          if (didPop) {
            final provider = context.read<TempIngredientProvider>();
            if (!providerFlg) {  // Provider에 재료가 없었다면
              print('뒤로가기: Provider 초기화');
              provider.clear(); // 또는 setIngredients([])
            }
            // 레시피 추천용 모드일 때 선택된 재료 초기화
            if (widget.isForRecommendation) {
              selectedIngredients.clear();
            }
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundColor,
          floatingActionButton: widget.isForRecommendation
              ? null // 레시피 추천용 모드에서는 SpeedDial 숨김
              : SpeedDial(
            spaceBetweenChildren: 14,
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            activeChild: const Icon(Icons.close, color: Colors.white),
            children: [
              SpeedDialChild(
                child: const Icon(Icons.remove, color: Colors.white),
                label: '재료 삭제하기',
                backgroundColor: AppColors.secondaryColor,
                onTap: () async {
                  final removedNames = await Navigator.push<List<String>>(
                    context,
                    MaterialPageRoute(builder: (_) => UserIngredientRemove()),
                  );
        
                  await _getUserIngredients();
        
                  // 삭제된 재료를 Provider에서도 제거
                  if (removedNames != null && removedNames.isNotEmpty) {
                    final provider = context.read<TempIngredientProvider>();
                    for (final name in removedNames) {
                      provider.removeIngredient(name);
                    }
                    print('Provider에서 제거된 재료: $removedNames');
                  }
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.add, color: Colors.white),
                label: '재료 추가하기',
                backgroundColor: AppColors.secondaryColor,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserIngredientAdd()),
                  );
                  _getUserIngredients();
                },
              ),
            ],
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/icon/icon_burgerMenu.png',
                width: 24,
                height: 24,
              ),
            ),
          ),
          appBar: const CustomAppBar(
            appName: '내 냉장고',
          ),
          drawer: const CustomDrawer(),
          body: Stack(
            children: [
              userIngredients.isEmpty
                  ? _buildEmptyState()
                  : _buildIngredientGrid(),
              // 확인 버튼 (레시피 추천용일 때만 표시, 재료가 선택되었을 때만 표시)
              if (widget.isForRecommendation && (selectedIngredients.isNotEmpty || providerFlg))
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0, // Stack의 최하단 (푸터 바로 위)
                  child: ElevatedButton(
                        onPressed: () {
                          if (providerFlg) {
                            // Provider에 이미 재료가 있는 경우
                            final Set<String> names =
                                selectedIngredients.map((e) => e['name'] as String).toSet();
                            final provider = Provider.of<TempIngredientProvider>(
                                context,
                                listen: false
                            );
                            final Set<String> mergeSet = {
                              ...names,
                              ...provider.ingredients
                            };
                            final List<String> finalList = mergeSet.toList();
                            provider.setIngredients(finalList);
                            print(provider.ingredients);
                            Navigator.pop(context);
                          } else {
                            // Provider에 재료가 없는 경우 (재료 편집 화면에서 호출한 경우 기존 재료 유지)
                            final Set<String> names =
                                selectedIngredients.map((e) => e['name'] as String).toSet();
                            final provider = Provider.of<TempIngredientProvider>(
                                context,
                                listen: false
                            );
                            // 기존 재료와 새로 선택한 재료 병합
                            final Set<String> mergeSet = {
                              ...names,
                              ...provider.ingredients
                            };
                            final List<String> finalList = mergeSet.toList();
                            provider.setIngredients(finalList);
                            print('Provider에 등록된 재료: ${provider.ingredients}');
                            // 모든 경우에 IngrecheckScreen으로 이동
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const IngrecheckScreen()
                                )
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8, // elevation을 높여서 컨텐츠 위에 표시
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                  ),
            ],
          ),
          bottomNavigationBar: CustomFooter(
            currentIndex: _currentIndex,
            onTap: (index) => _onFooterTap(index, authProvider, context),
          ),
        ),
      );
    }

    Widget _buildEmptyState() {
      final Size screenSize = MediaQuery.of(context).size;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.highlight_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              '등록된 재료가 없어요',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '새로운 재료를 추가해보세요',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: screenSize.width * 0.5,
              height: screenSize.width * 0.13,
              child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserIngredientAdd()),
                    );
                    _getUserIngredients();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor, // 버튼 배경색
                    foregroundColor: AppColors.textWhite,           // 글자색
                    // padding: const EdgeInsets.symmetric(
                    //   horizontal: 24,
                    //   vertical: 12,
                    // ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text('재료 추가하기',
                    style: TextStyle(
                        fontSize: screenSize.width * 0.042
                    ),
                  )
              ),
            )
          ],
        ),
      );
    }

    Widget _buildIngredientGrid() {
      final Size screenSize = MediaQuery.of(context).size;
      final double screenWidth = screenSize.width;
      final double itemWidth = (screenWidth - 32 - 12) / 2; // padding(32) + spacing(12) 제외
      final double itemHeight = 60.0; // 높이 직접 지정 (원하는 값으로 변경 가능)
      
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // 하단에 확인 버튼 공간 확보
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12, // 가로 간격
            runSpacing: 12, // 세로 간격
            children: userIngredients.map((ingredient) {
              final bool isSelected = _isSelected(ingredient);
              // 레시피 추천용 모드에서만 중복 체크 (단, Provider에 재료가 없을 때는 중복 체크 안 함)
              final bool isDuplicate = widget.isForRecommendation && 
                  providerFlg && 
                  isAlreadyAdded(ingredient['name']!);
              
              return GestureDetector(
                onTap: widget.isForRecommendation && !isDuplicate
                    ? () {
                      setState(() {
                        if (_isSelected(ingredient)) {
                          selectedIngredients.removeWhere((item) =>
                          item['name'] == ingredient['name'] &&
                              item['category'] == ingredient['category']);
                        } else {
                          selectedIngredients.add(ingredient);
                        }
                      });
                    }
                    : null, // 관리용 모드에서는 클릭 비활성화
                child: SizedBox(
                  width: itemWidth,
                  height: itemHeight, // 높이 직접 지정
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDuplicate
                          ? Colors.grey.shade300
                          : isSelected
                            ? AppColors.secondaryColor.withAlpha(30)
                            : Colors.white,
                      border: Border.all(
                          color: AppColors.primaryColor,
                          width: 1
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          ingredient['name'] ?? '',
                          style: TextStyle(
                            fontSize: screenSize.width * 0.038,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          ingredient['category'] ?? '',
                          style: TextStyle(
                            fontSize: screenSize.width * 0.028,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

  }