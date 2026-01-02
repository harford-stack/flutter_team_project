  // 푸터로 진입하는 재료 등록

  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
  import '../common/app_colors.dart';
  import '../common/custom_appbar.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import '../auth/login_screen.dart';
  import 'dart:async';
  import 'package:flutter_speed_dial/flutter_speed_dial.dart';
  import 'user_ingredient_add.dart';
  import 'user_ingredient_remove.dart';
  import '../providers/temp_ingre_provider.dart';


  class UserRefrigerator extends StatefulWidget {
    const UserRefrigerator({super.key});

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

    bool _isSelected(Map<String, String> ingredient) {
      return selectedIngredients.any((item) =>
      item['name'] == ingredient['name'] &&
          item['category'] == ingredient['category']);
    }

    List<String> getDuplicateIngredients() {
      final selectedNames =
      userIngredients.map((e) => e['name']!).toSet();

      final providerNames =
      context.read<TempIngredientProvider>().ingredients.toSet();

      print('임시 재료: $providerNames');
      return selectedNames.intersection(providerNames).toList();
    }

    bool isAlreadyAdded(String name) {
      return context
          .read<TempIngredientProvider>()
          .ingredients
          .contains(name);
    }

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

      print('보유 재료: $userIngredients');
      print('중복 재료: $duplicates');

      print(userIngredients.length);

      print(categories);

      return userIngredients;
    }

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
          print("로그인 상태: ${user.email}");
          if (mounted) {
            setState(() {
              loginFlg = true;
            });
          }
        }
      });
    }

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

    @override
    void initState() {
      // TODO: implement initState
      super.initState();
      _checkLoginStatus();
      _listenToAuthChanges();
      _getUserIngredients();
    }

    @override
    void dispose() {
      _authSubscription?.cancel(); // 리스너 해제
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
      return Scaffold(
        floatingActionButton: SpeedDial(
          spaceBetweenChildren: 14,
          icon: Icons.menu,
          activeIcon: Icons.close,
          backgroundColor: AppColors.secondaryColor,
          foregroundColor: AppColors.textDark,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.remove),
              label: '재료 삭제하기',
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
              child: const Icon(Icons.add),
              label: '재료 추가하기',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserIngredientAdd()),
                );
                _getUserIngredients();
              },
            ),
          ],
        ),
        appBar: AppBar(
          title: Text('내 냉장고'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.textWhite,
        ),
        body: userIngredients.isEmpty
            ? _buildEmptyState()
            : _buildIngredientGrid(),
        bottomNavigationBar: SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                    onPressed: () {
                      final Set<String> names =
                        selectedIngredients.map((e) => e['name'] as String).toSet();
                      // print(names);

                      late final provider = Provider.of<TempIngredientProvider>(
                          context,
                          listen: false
                      );

                      // print(provider.ingredients);

                      final Set<String> mergeSet = {
                        ...names,
                        ...provider.ingredients
                      };
                      // print(mergeSet);

                      final List<String> finalList = mergeSet.toList();

                      provider.setIngredients(finalList);

                      // print(provider.ingredients);

                      // print(finalList);

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(13),
                        side: BorderSide(
                          color: AppColors.secondaryColor,
                          width: 1.5
                        )
                      )
                    ),
                    child: Text('확인',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.primaryColor
                      ),
                    )
                ),
              ),
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

      return Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: userIngredients.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,          // ⭐ 2개씩
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final ingredient = userIngredients[index];
            final bool isSelected = _isSelected(ingredient);
            final bool isDuplicate = isAlreadyAdded(ingredient['name']!);

            return GestureDetector(
              onTap: isDuplicate
                  ? null
                  : () {
                    setState(() {
                      if (_isSelected(ingredient)) {
                        selectedIngredients.removeWhere((item) =>
                        item['name'] == ingredient['name'] &&
                            item['category'] == ingredient['category']);
                      } else {
                        selectedIngredients.add(ingredient);
                      }
                    });
              },
              // onTap: () {
              //   setState(() {
              //     if (_isSelected(ingredient)) {
              //       selectedIngredients.removeWhere((item) =>
              //       item['name'] == ingredient['name'] &&
              //           item['category'] == ingredient['category']);
              //     } else {
              //       selectedIngredients.add(ingredient);
              //     }
              //   });
              //   // print(selectedIngredients);
              // },
              child: Container(
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
                  children: [
                    // Icon(
                    //   Icons.kitchen,
                    //   size: 40,
                    //   color: AppColors.primaryColor,
                    // ),
                    const SizedBox(height: 10),
                    Text(
                      ingredient['name'] ?? '',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ingredient['category'] ?? '',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.032,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

  }

  //할거
  //확인 눌렀을 때, selectIngredients를 provider에 넣기(완)
  //내 냉장고로 이동할 때, 기존 ingredients를 받아온 후,
  // ingredients와 내 재료중 겹치는게 있으면 이미 체크되있도록 하기