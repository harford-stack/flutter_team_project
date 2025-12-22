import 'package:flutter/material.dart';

/// 로그인 화면
/// 
/// 이 파일은 화면(페이지)만 작성합니다.
/// 
/// 📌 작성 가이드:
/// - UI 레이아웃과 화면 구성만 작성
/// - 재사용 가능한 위젯은 widgets/ 폴더에 별도 파일로 작성
/// - 비즈니스 로직은 services/ 폴더의 서비스 파일에 작성
/// - 데이터 모델은 models/ 폴더의 모델 파일 사용
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('로그인 화면'),
      ),
    );
  }
}
