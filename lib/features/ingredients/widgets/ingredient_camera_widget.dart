import 'package:flutter/material.dart';

/// 재료 사진 촬영 위젯
/// 
/// 이 파일은 재사용 가능한 위젯(UI 컴포넌트)을 작성합니다.
/// 
/// 📌 작성 가이드:
/// - 화면의 일부 UI 컴포넌트만 작성
/// - 여러 화면에서 재사용 가능하도록 설계
/// - Scaffold 사용하지 않음 (화면이 아니므로)
/// - 필요한 로직은 services/ 폴더의 서비스 파일에 작성
/// 
/// ⚠️ 주의:
/// - 이 폴더는 재사용 가능한 위젯만 작성
/// - 한 화면에서만 사용하는 위젯은 해당 화면 파일 안에 private 클래스로 작성
class IngredientCameraWidget extends StatelessWidget {
  const IngredientCameraWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
