// lib/notifications/widgets/notification_list.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import 'notification_model.dart';
import 'notification_service.dart';
import 'notification_card.dart';
import '../../community/screens/community_detail_screen.dart';

/// 通知列表组件
class NotificationList extends StatelessWidget {
  final String userId;
  final NotificationType type;
  final int? limit;

  const NotificationList({
    Key? key,
    required this.userId,
    required this.type,
    this.limit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    print('🔔 NotificationList build - userId: $userId, type: $type');

    return StreamBuilder<List<NotificationModel>>(
      stream: notificationService.getUserNotificationsByType(userId, type),
      builder: (context, snapshot) {
        print('📊 Stream state: ${snapshot.connectionState}');
        print('📊 Has data: ${snapshot.hasData}');
        print('📊 Data length: ${snapshot.data?.length}');
        print('📊 Error: ${snapshot.error}');

        // 加载中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        // 错误处理
        if (snapshot.hasError) {
          print('❌ Stream error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                SizedBox(height: 16),
                Text(
                  '알림을 불러오는데 실패했습니다',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // 无数据或空列表
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('📭 Empty notifications');
          return _buildEmptyState();
        }

        List<NotificationModel> notifications = snapshot.data!;
        print('✅ Showing ${notifications.length} notifications');

        // 限制显示数量
        if (limit != null && notifications.length > limit!) {
          notifications = notifications.sublist(0, limit!);
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: notifications.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[100],
          ),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            print('🎴 Building card for notification: ${notification.id}');

            return NotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(context, notification),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEmptyIcon(),
            size: 64,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            '알림이 없습니다',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEmptyIcon() {
    switch (type) {
      case NotificationType.bookmark:
        return Icons.bookmark_outline;
      case NotificationType.comment:
        return Icons.chat_bubble_outline;
      case NotificationType.reply:
        return Icons.reply;
    }
  }

  /// ✅ 点击通知处理
  Future<void> _handleNotificationTap(
      BuildContext context,
      NotificationModel notification,
      ) async {
    print('👆 Notification tapped: ${notification.id}');

    final notificationService = NotificationService();

    // ===== 检查帖子是否存在 =====
    final postExists = await notificationService.checkPostExists(notification.postId);

    if (!postExists) {
      print('❌ 帖子已被删除: ${notification.postId}');

      if (context.mounted) {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('알림 오류'),
              ],
            ),
            content: Text('원본 게시글이 삭제되었습니다.\n이 알림을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('삭제'),
              ),
            ],
          ),
        );

        if (shouldDelete == true) {
          await notificationService.deleteNotification(userId, notification.id);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('알림이 삭제되었습니다'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }

      return;
    }

    // ===== ✅ 检查评论/回复是否存在 =====
    if (notification.commentId != null) {
      final commentExists = await notificationService.checkCommentExists(
        notification.postId,
        notification.commentId!,
      );

      if (!commentExists) {
        print('❌ 댓글이 삭제되었습니다: ${notification.commentId}');

        if (context.mounted) {
          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('알림 오류'),
                ],
              ),
              content: Text('원본 댓글이 삭제되었습니다.\n이 알림을 삭제하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('삭제'),
                ),
              ],
            ),
          );

          if (shouldDelete == true) {
            await notificationService.deleteNotification(userId, notification.id);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('알림이 삭제되었습니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }

        return;
      }
    }

    // ===== 标记为已读 =====
    if (!notification.isRead) {
      await notificationService.markAsRead(userId, notification.id);
      print('✅ Marked as read');
    }

    // ===== ✅ 简化：统一使用 commentId 作为高亮ID =====
    String? highlightId = notification.commentId;

    if (highlightId != null) {
      print('🎯 Highlight comment: $highlightId');
    } else {
      print('📌 No highlight (bookmark notification)');
    }

    // ===== 跳转到帖子详情页 =====
    if (context.mounted) {
      print('🚀 Navigating to post: ${notification.postId}');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(
            postId: notification.postId,
            highlightCommentId: highlightId,  // ✅ 直接使用 commentId
          ),
        ),
      );
    }
  }
}