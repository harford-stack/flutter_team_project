// ============================================
// lib/notifications/notification_tab.dart
// 역할: 탭 전환 + 읽지 않은 알림 개수 표시
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import 'notification_model.dart';
import 'notification_service.dart';
import '../../common/app_colors.dart';
import 'notification_list.dart';

/// 알림 탭 컴포넌트 (탭 전환 + 읽지 않은 알림 뱃지 표시)
///
/// 역할:
/// - 3개 탭 제공: 북마크, 댓글, 대댓글
/// - 각 탭에 읽지 않은 알림 개수 뱃지 표시
/// - "모두 읽음" 버튼으로 모든 알림 일괄 읽음 처리
class NotificationTab extends StatefulWidget {
  const NotificationTab({Key? key}) : super(key: key);

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab>
    with SingleTickerProviderStateMixin {
  /// =====================================================================================
  /// 변수 선언
  /// =====================================================================================
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();

  /// =====================================================================================
  /// 초기화
  /// =====================================================================================
  @override
  void initState() {
    super.initState();
    // 3개 탭을 위한 컨트롤러 생성
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// =====================================================================================
  /// UI 구현
  /// =====================================================================================
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    // 로그인하지 않은 경우
    if (currentUser == null) {
      return _buildLoginRequired();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(currentUser.uid),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 탭 1: 북마크 알림
          NotificationList(
            userId: currentUser.uid,
            type: NotificationType.bookmark,
          ),
          // 탭 2: 댓글 알림
          NotificationList(
            userId: currentUser.uid,
            type: NotificationType.comment,
          ),
          // 탭 3: 대댓글 알림
          NotificationList(
            userId: currentUser.uid,
            type: NotificationType.reply,
          ),
        ],
      ),
    );
  }

  /// =====================================================================================
  /// AppBar 구현
  /// =====================================================================================
  /// AppBar 빌드 (탭바 포함)
  PreferredSizeWidget _buildAppBar(String userId) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        '알림',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      // 우측: "모두 읽음" 버튼
      actions: [
        TextButton(
          onPressed: () async {
            await _notificationService.markAllAsRead(userId);
          },
          child: Text(
            '모두 읽음',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
      // 하단: 탭바
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryColor,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.black,
            labelStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelColor: Colors.grey[600],
            unselectedLabelStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
            ),
            tabs: [
              _buildTabWithBadge(userId, '북마크', NotificationType.bookmark),
              _buildTabWithBadge(userId, '댓글', NotificationType.comment),
              _buildTabWithBadge(userId, '대댓글', NotificationType.reply),
            ],
          ),
        ),
      ),
    );
  }

  /// =====================================================================================
  /// 탭 + 뱃지 구현
  /// =====================================================================================
  /// 읽지 않은 알림 개수를 표시하는 탭
  ///
  /// 뱃지 표시 규칙:
  /// - 읽지 않은 알림이 없으면 표시 안 함
  /// - 1~9개: 빨간 점
  /// - 10개 이상: "9+" 텍스트
  Widget _buildTabWithBadge(String userId, String label, NotificationType type) {
    return StreamBuilder<int>(
      stream: _notificationService.getUnreadCountByType(userId, type),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Tab(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 탭 텍스트
              Align(
                alignment: Alignment.center,
                child: Text(label),
              ),
              // 읽지 않은 알림 뱃지
              if (unreadCount > 0)
                Positioned(
                  right: -12,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                    // 10개 이상이면 "9+" 텍스트 표시
                    child: unreadCount > 9
                        ? Text(
                      '9+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// =====================================================================================
  /// 로그인 필요 화면
  /// =====================================================================================
  /// 로그인하지 않은 사용자에게 표시되는 화면
  Widget _buildLoginRequired() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '알림',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Text(
          '로그인이 필요합니다',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}