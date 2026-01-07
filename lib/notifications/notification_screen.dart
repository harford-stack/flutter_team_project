// ============================================
// lib/notifications/notification_screen.dart
// 역할: 알림 페이지 진입점
// ============================================

import 'package:flutter/material.dart';
import 'notification_tab.dart';

/// 알림 화면 진입점
///
/// 역할 설명:
/// - 이 파일은 단순한 진입점 역할만 수행
/// - 실제 알림 기능은 모두 notification_tab.dart에서 구현
///
/// 설계 이점:
/// 1. 단일 책임 원칙(SRP) 준수 - 각 파일이 하나의 역할만 담당
/// 2. 재사용성 향상 - 다른 곳에서 NotificationTab을 쉽게 재사용 가능
/// 3. 확장성 좋음 - 향후 추가 로직이 필요하면 이 파일에서 처리 가능
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // NotificationTab 위젯을 직접 반환
    // 모든 탭 전환, 알림 목록, 클릭 처리 등의 기능은 NotificationTab에서 구현
    return NotificationTab();
  }
}