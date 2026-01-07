// ============================================
// lib/notifications/widgets/notification_list.dart
// 역할: 알림 목록 표시 및 클릭 처리
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import 'notification_model.dart';
import 'notification_service.dart';
import 'notification_card.dart';
import '../../community/screens/community_detail_screen.dart';

/// 알림 목록 컴포넌트
///
/// 역할:
/// - 특정 타입(북마크/댓글/대댓글)의 알림 목록 표시
/// - 실시간 스트림으로 알림 변경사항 반영
/// - 알림 클릭 시 게시글 상세 페이지로 이동
/// - 삭제된 게시글/댓글에 대한 알림 처리
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

    return StreamBuilder<List<NotificationModel>>(
      stream: notificationService.getUserNotificationsByType(userId, type),
      builder: (context, snapshot) {
        // 1. 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        // 2. 에러 발생
        if (snapshot.hasError) {
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

        // 3. 데이터 없음 또는 빈 목록
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        // 4. 알림 목록 표시
        List<NotificationModel> notifications = snapshot.data!;

        // limit이 설정되어 있으면 개수 제한
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

            return NotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(context, notification),
            );
          },
        );
      },
    );
  }

  /// =====================================================================================
  /// 빈 상태 UI
  /// =====================================================================================
  /// 알림이 없을 때 표시되는 화면
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

  /// 알림 타입에 따른 빈 상태 아이콘
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

  /// =====================================================================================
  /// 알림 클릭 처리
  /// =====================================================================================
  /// 알림 클릭 시 실행되는 함수
  ///
  /// 처리 순서:
  /// 1. 게시글 존재 여부 확인 → 없으면 삭제 확인 대화상자
  /// 2. 댓글/대댓글 존재 여부 확인 → 없으면 삭제 확인 대화상자
  /// 3. 읽지 않은 알림이면 읽음 처리
  /// 4. 게시글 상세 페이지로 이동 (해당 댓글 하이라이트)
  ///
  /// 주의사항:
  /// - 삭제된 콘텐츠는 사용자에게 알림 삭제 여부를 물어봄
  /// - 알림 삭제는 사용자가 직접 선택
  Future<void> _handleNotificationTap(
      BuildContext context,
      NotificationModel notification,
      ) async {
    final notificationService = NotificationService();

    // ===== 1단계: 게시글 존재 여부 확인 =====
    final postExists = await notificationService.checkPostExists(notification.postId);

    if (!postExists) {
      // 게시글이 삭제된 경우
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

        // 사용자가 삭제를 선택한 경우
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

    // ===== 2단계: 댓글/대댓글 존재 여부 확인 =====
    if (notification.commentId != null) {
      final commentExists = await notificationService.checkCommentExists(
        notification.postId,
        notification.commentId!,
      );

      if (!commentExists) {
        // 댓글이 삭제된 경우
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

    // ===== 3단계: 읽지 않은 알림이면 읽음 처리 =====
    if (!notification.isRead) {
      await notificationService.markAsRead(userId, notification.id);
    }

    // ===== 4단계: 하이라이트할 댓글 ID 설정 =====
    // 북마크: null (게시글만 보여줌)
    // 댓글/대댓글: commentId (해당 댓글을 하이라이트)
    String? highlightId = notification.commentId;

    // ===== 5단계: 게시글 상세 페이지로 이동 =====
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(
            postId: notification.postId,
            highlightCommentId: highlightId,  // 하이라이트할 댓글 ID
          ),
        ),
      );
    }
  }
}