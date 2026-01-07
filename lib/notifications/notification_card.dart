// ============================================
// lib/notifications/notification_card.dart
// 역할: 단일 알림 카드의 스타일과 내용 표시
// ============================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_model.dart';
import '../common/app_colors.dart';

/// 단일 알림 카드 컴포넌트 (스타일과 내용 표시 담당)
///
/// 역할:
/// - 알림 유형(북마크, 댓글, 대댓글)에 따라 다른 UI 표시
/// - 읽음/안읽음 상태 시각적 표현
/// - 게시글/댓글 내용 미리보기 제공
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
        // 읽지 않은 알림은 연한 파란색 배경으로 표시
        color: notification.isRead
            ? Colors.white
            : Colors.blue[50]?.withOpacity(0.3),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 왼쪽: 알림 타입 아이콘
            _buildLeadingIcon(),
            SizedBox(width: 12),

            // 2. 중앙: 알림 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2-1. 상단: 닉네임 + 우측 화살표
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

                  // 2-2. 중앙: 알림 내용 (타입별로 다름)
                  _buildNotificationContent(context),
                  SizedBox(height: 4),

                  // 2-3. 하단: 시간 표시
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

            // 3. 오른쪽: 읽지 않은 알림 표시 (빨간 점)
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

  /// =====================================================================================
  /// 알림 타입별 아이콘 빌드
  /// =====================================================================================
  /// 알림 타입에 따라 다른 아이콘과 색상 표시
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

  /// =====================================================================================
  /// 알림 타입별 내용 빌드
  /// =====================================================================================
  /// 알림 타입(북마크/댓글/대댓글)에 따라 다른 내용 표시
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

  /// 1. 북마크 알림 내용
  ///
  /// 표시 내용:
  /// - "게시글을 북마크했습니다" 메시지
  /// - 게시글 제목 미리보기 (회색 박스)
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

  /// 2. 댓글 알림 내용
  ///
  /// 표시 내용:
  /// - 게시글 제목 (있으면)
  /// - 댓글 내용 미리보기 (회색 박스)
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
            // 게시글 제목 표시 (있으면)
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
            // 댓글 내용 박스
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

  /// 3. 대댓글 알림 내용
  ///
  /// 표시 내용:
  /// - 내 원래 댓글 미리보기 (회색 박스, "내 댓글:" 라벨 포함)
  /// - 받은 대댓글 내용 (회색 박스)
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
            // 내 원래 댓글 표시 (있으면)
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
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],
            // 받은 대댓글 내용 박스
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

  /// =====================================================================================
  /// 보조 함수들
  /// =====================================================================================

  /// 게시글 정보 가져오기
  ///
  /// 기능:
  /// - Firestore에서 게시글 문서를 읽어옴
  /// - 에러 발생 시 null 반환
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
      return null;
    }
  }

  /// 원래 댓글 내용 가져오기 (대댓글용)
  ///
  /// 작동 방식:
  /// 1. 새 대댓글 문서를 읽어옴 (commentId로)
  /// 2. 대댓글의 pComment 필드에서 원래 댓글 ID 획득
  /// 3. 원래 댓글 문서를 읽어서 내용 반환
  ///
  /// 주의사항:
  /// - 대댓글이나 원래 댓글이 삭제되었으면 null 반환
  /// - 에러 발생 시 null 반환
  Future<String?> _getOriginalComment(
      String postId,
      String? replyCommentId,
      ) async {
    if (replyCommentId == null) return null;

    try {
      // 1단계: 대댓글 문서 가져오기
      final replyDoc = await FirebaseFirestore.instance
          .collection('post')
          .doc(postId)
          .collection('comment')
          .doc(replyCommentId)
          .get();

      if (!replyDoc.exists) {
        return null;
      }

      // 2단계: 대댓글에서 원래 댓글 ID(pComment) 가져오기
      final pCommentId = replyDoc.data()?['pComment'] as String?;

      if (pCommentId == null) {
        return null;
      }

      // 3단계: 원래 댓글 내용 가져오기
      final originalDoc = await FirebaseFirestore.instance
          .collection('post')
          .doc(postId)
          .collection('comment')
          .doc(pCommentId)
          .get();

      if (originalDoc.exists) {
        final content = originalDoc.data()?['content'] as String?;
        return content;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 날짜 포맷팅
  ///
  /// 표시 형식:
  /// - 1분 미만: "방금 전"
  /// - 1시간 미만: "N분 전"
  /// - 1일 미만: "N시간 전"
  /// - 7일 미만: "N일 전"
  /// - 7일 이상: "YYYY.MM.DD"
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