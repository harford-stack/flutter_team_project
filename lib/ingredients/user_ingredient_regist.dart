// 푸터로 진입하는 재료 등록

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../common/app_colors.dart';
import '../common/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import 'dart:async';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'user_ingredient_add.dart';


class UserIngredientRegist extends StatefulWidget {
  const UserIngredientRegist({super.key});

  @override
  State<UserIngredientRegist> createState() => _UserIngredientRegistState();
}

class _UserIngredientRegistState extends State<UserIngredientRegist> {
  bool loginFlg = false;
  StreamSubscription<User?>? _authSubscription;

  void _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    // final uid = FirebaseAuth.instance.currentUser!.uid;

    // final doc = await FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(uid)
    //     .get();
    //
    // final docInfo = await doc.data();

    if (user != null) {
      print("로그인 상태: ${user.email}");
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
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // 리스너 해제
    super.dispose();
  }

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
              child: Icon(Icons.remove),
              label: '재료 삭제하기',
              onTap: (){

              }
          )
          ,
          SpeedDialChild(
              child: Icon(Icons.add),
              label: '재료 추가하기',
              onTap: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_)=>UserIngredientAdd()
                    )
                );
              }
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              '재료 등록 화면',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
            // const SizedBox(height: 10),
            // Text(
            //   '추후 구현 예정',
            //   style: TextStyle(
            //     fontSize: 14,
            //     color: Colors.grey[400],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}