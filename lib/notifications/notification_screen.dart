// lib/notifications/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'notification_model.dart';
import 'notification_service.dart';
import '../common/app_colors.dart';
import '../community/screens/community_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('알림')),
        body: Center(child: Text('로그인이 필요합니다')),
      );
    }

    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: Text('알림'),
        backgroundColor: AppColors.backgroundColor,
        actions: [
          TextButton(
            onPressed: () async {
              await notificationService.markAllAsRead(currentUser.uid);
            },
            child: Text('모두 읽음', style: TextStyle(color: AppColors.primaryColor)),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.getUserNotificationsStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                '알림이 없습니다',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(
                context,
                notification,
                currentUser.uid,
                notificationService,
              );
            },
          );
        },
      ),
    );
  }

  // ✅ 这是唯一修改的方法
  Widget _buildNotificationItem(
      BuildContext context,
      NotificationModel notification,
      String userId,
      NotificationService service,
      ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        service.deleteNotification(userId, notification.id);
      },
      child: Container(
        color: notification.isRead ? Colors.white : Colors.blue[50],
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                child: Icon(
                  _getIconForType(notification.type),
                  color: AppColors.primaryColor,
                ),
              ),
              if (!notification.isRead)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            notification.type.getDisplayText(notification.fromNickName),
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 显示评论内容
              if (notification.commentContent != null)
                Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    notification.commentContent!.length > 30
                        ? '${notification.commentContent!.substring(0, 30)}...'
                        : notification.commentContent!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              Text(
                _formatDate(notification.cdate),
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          onTap: () async {
            if (!notification.isRead) {
              await service.markAsRead(userId, notification.id);
            }

            // ✅ 回复时高亮被回复的评论
            String? highlightId;
            if (notification.type == NotificationType.reply) {
              highlightId = notification.commentId;
            } else if (notification.type == NotificationType.comment) {
              highlightId = null;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(
                  postId: notification.postId,
                  highlightCommentId: highlightId,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.bookmark:
        return Icons.bookmark;
      case NotificationType.reply:
        return Icons.reply;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${date.year}.${date.month}.${date.day}';
  }
}