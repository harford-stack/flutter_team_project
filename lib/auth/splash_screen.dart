import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // 스플래시 화면 표시 시간 (최소 2초)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 인증 상태 확인 대기
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // 자동 로그인 체크 (이미 로그인된 사용자는 홈 화면으로)
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // 비로그인 사용자는 홈 화면으로 (로그인 화면 건너뛰기)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(5, 0), // 오른쪽으로 이동하여 이미지 내 텍스트가 가운데 보이도록
              child: Image.asset(
                // 'assets/image_appLogo3.PNG',
                'assets/image_appLogo4.png',
                fit: BoxFit.contain,
                width: 250,
                height: 250,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
