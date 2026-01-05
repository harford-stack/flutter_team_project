// ============================================
// 文件 1: lib/notifications/widgets/notification_tab.dart
// 职责：只负责 Tab 切换
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import 'notification_model.dart';
import 'notification_service.dart';
import '../../common/app_colors.dart';
import 'notification_list.dart';

/// 通知 Tab 组件（只负责 Tab 切换）
class NotificationTab extends StatefulWidget {
  const NotificationTab({Key? key}) : super(key: key);

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      return _buildLoginRequired();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(currentUser.uid),
      body: TabBarView(
        controller: _tabController,
        children: [
          NotificationList(
            userId: currentUser.uid,
            type: NotificationType.bookmark,
          ),
          NotificationList(
            userId: currentUser.uid,
            type: NotificationType.comment,
          ),
          NotificationList(
            userId: currentUser.uid,
            type: NotificationType.reply,
          ),
        ],
      ),
    );
  }

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
              Tab(text: '북마크'),
              Tab(text: '댓글'),
              Tab(text: '대댓글'),
            ],
          ),
        ),
      ),
    );
  }

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