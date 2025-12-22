import 'package:flutter/material.dart';

/// 홈 화면
/// 
/// 이 파일은 화면(페이지)만 작성합니다.
/// 
/// 📌 작성 가이드:
/// - UI 레이아웃과 화면 구성만 작성
/// 
/// 🔄 위젯 작성 위치 (판단 기준):
/// 
/// 1단계: "다른 기능에서도 쓸 수 있나?"
///   → 예: widgets/common/ (공통 위젯)
/// 
/// 2단계: "같은 기능의 다른 화면에서도 쓸 수 있나?"
///   → 예: features/[기능]/widgets/ (기능 전용 위젯)
/// 
/// 3단계: "이 화면에서만 쓰나?"
///   → 예: 같은 파일 안에 private 클래스 (일회용 위젯)
/// 
/// 확실하지 않으면 일회용으로 시작하고, 필요할 때 리팩토링!
/// 
/// 📝 비즈니스 로직:
/// - services/ 폴더의 서비스 파일에 작성
/// 
/// 📊 데이터 모델:
/// - models/ 폴더의 모델 파일 사용
/// 
/// 예시:
/// - 버튼 클릭 → services/auth_service.dart의 메서드 호출
/// - 리스트 표시 → models/recipe.dart 모델 사용
/// - 공통 UI → widgets/common/ 폴더의 위젯 사용
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('홈 화면'),
      ),
    );
  }
}

// 일회용 위젯 예시 (이 화면에서만 사용하는 경우)
// class _HomeBannerWidget extends StatelessWidget {
//   const _HomeBannerWidget();
//   
//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
// }
