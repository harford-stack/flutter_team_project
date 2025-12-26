import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../common/app_colors.dart';
import 'auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

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
    await Future.delayed(const Duration(seconds: 2));

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
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GIF 아이콘 (임시로 아이콘 사용, 나중에 실제 GIF로 교체 가능)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 80,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            // 어플 이름
            const Text(
              '어플 이름',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
