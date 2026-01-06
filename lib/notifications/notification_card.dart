// ============================================
// lib/notifications/notification_card.dart
// 职责：负责单个通知卡片的样式和内容展示
// ============================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_model.dart';
import '../common/app_colors.dart';

/// 单个通知卡片组件（负责样式和内容展示）
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead
            ? Colors.white
            : Colors.blue[50]?.withOpacity(0.3),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingIcon(),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.fromNickName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 22,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  _buildNotificationContent(context),
                  SizedBox(height: 4),
                  Text(
                    _formatDate(notification.cdate),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.bookmark:
        iconData = Icons.bookmark;
        iconColor = Colors.orange;
        break;
      case NotificationType.comment:
        iconData = Icons.chat_bubble;
        iconColor = Colors.blue;
        break;
      case NotificationType.reply:
        iconData = Icons.reply;
        iconColor = Colors.green;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: 20,
        color: iconColor,
      ),
    );
  }

  Widget _buildNotificationContent(BuildContext context) {
    switch (notification.type) {
      case NotificationType.bookmark:
        return _buildBookmarkContent();
      case NotificationType.comment:
        return _buildCommentContent();
      case NotificationType.reply:
        return _buildReplyContent();
    }
  }

  Widget _buildBookmarkContent() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getPostInfo(notification.postId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            '게시글을 북마크했습니다',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          );
        }

        final postTitle = snapshot.data!['title'] ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '게시글을 북마크했습니다',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                postTitle.length > 30
                    ? '${postTitle.substring(0, 30)}...'
                    : postTitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentContent() {
    final commentContent = notification.commentContent ?? '';

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getPostInfo(notification.postId),
      builder: (context, snapshot) {
        final postTitle = snapshot.hasData
            ? (snapshot.data!['title'] ?? '')
            : '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (postTitle.isNotEmpty) ...[
              Text(
                postTitle.length > 25
                    ? '${postTitle.substring(0, 25)}...'
                    : postTitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6),
            ],
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                commentContent.length > 50
                    ? '${commentContent.substring(0, 50)}...'
                    : commentContent,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReplyContent() {
    final replyContent = notification.commentContent ?? '';

    return FutureBuilder<String?>(
      future: _getOriginalComment(
        notification.postId,
        notification.commentId,
      ),
      builder: (context, snapshot) {
        final originalComment = snapshot.data ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (originalComment.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text(
                      '내 댓글: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        originalComment.length > 20
                            ? '${originalComment.substring(0, 20)}...'
                            : originalComment,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Spacer(),
                    // Icon(
                    //   Icons.chevron_right,
                    //   size: 22,
                    //   color: Colors.grey[400],
                    // ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                replyContent.length > 50
                    ? '${replyContent.substring(0, 50)}...'
                    : replyContent,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // 辅助方法
  // ============================================

  /// 获取帖子信息
  Future<Map<String, dynamic>?> _getPostInfo(String postId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('post')
          .doc(postId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('게시글 정보 가져오기 실패: $e');
      return null;
    }
  }

  /// ✅ 修改：获取被回复的原始评论内容
  /// 通过新回复的ID -> 找到它的pComment -> 获取原始评论内容
  Future<String?> _getOriginalComment(
      String postId,
      String? replyCommentId,
      ) async {
    if (replyCommentId == null) return null;

    try {
      // 第1步：获取新回复评论的数据
      final replyDoc = await FirebaseFirestore.instance
          .collection('post')
          .doc(postId)
          .collection('comment')
          .doc(replyCommentId)
          .get();

      if (!replyDoc.exists) {
        print('❌ 回复评论不存在: $replyCommentId');
        return null;
      }

      // 第2步：从回复评论中获取 pComment（被回复的评论ID）
      final pCommentId = replyDoc.data()?['pComment'] as String?;

      if (pCommentId == null) {
        print('❌ 没有找到父评论ID');
        return null;
      }

      print('✅ 找到父评论ID: $pCommentId');

      // 第3步：获取被回复的原始评论内容
      final originalDoc = await FirebaseFirestore.instance
          .collection('post')
          .doc(postId)
          .collection('comment')
          .doc(pCommentId)
          .get();

      if (originalDoc.exists) {
        final content = originalDoc.data()?['content'] as String?;
        print('✅ 找到原始评论内容: $content');
        return content;
      }

      return null;
    } catch (e) {
      print('❌ 원본 댓글 가져오기 실패: $e');
      return null;
    }
  }

  /// ✅ 添加：格式化日期显示
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