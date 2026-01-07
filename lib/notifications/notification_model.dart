// ==================================================================================
// 2. notification_model.dart - 알림 데이터 모델
// ==================================================================================
// lib/notifications/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 알림 데이터 모델
class NotificationModel {
  /// =====================================================================================
  /// 필드
  /// =====================================================================================
  final String id; // 알림 ID
  final String postId; // 게시글 ID
  final String? commentId; // 댓글 ID (북마크 알림은 null)
  final String fromUserId; // 알림을 보낸 사용자 ID
  final String fromNickName; // 알림을 보낸 사용자 닉네임
  final NotificationType type; // 알림 타입 (중요: 판단 로직 단순화 및 확장성을 위해 필수)
  final String? commentContent; // 댓글/답글 내용
  final bool isRead; // 읽음 여부
  final DateTime cdate; // 생성 날짜

  NotificationModel({
    required this.id,
    required this.postId,
    this.commentId,
    required this.fromUserId,
    required this.fromNickName,
    this.commentContent,
    required this.type,
    this.isRead = false,
    required this.cdate,
  });

  /// Firestore 문서에서 모델 생성
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      commentId: data['commentId'],
      fromUserId: data['fromUserId'] ?? '',
      fromNickName: data['fromNickName'] ?? '',
      commentContent: data['commentContent'],
      type: NotificationType.fromString(data['type'] ?? 'comment'),
      isRead: data['isRead'] ?? false,
      cdate: (data['cdate'] as Timestamp).toDate(),
    );
  }

  /// 모델을 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      if (commentId != null) 'commentId': commentId,
      'fromUserId': fromUserId,
      'fromNickName': fromNickName,
      if (commentContent != null) 'commentContent': commentContent,
      'type': type.toString(),
      'isRead': isRead,
      'cdate': Timestamp.fromDate(cdate),
    };
  }
}

/// 알림 타입 열거형
enum NotificationType {
  comment, // 댓글 알림
  bookmark, // 북마크 알림
  reply; // 답글 알림

  @override
  String toString() {
    return name;
  }

  /// 문자열을 NotificationType으로 변환
  static NotificationType fromString(String type) {
    switch (type) {
      case 'comment':
        return NotificationType.comment;
      case 'bookmark':
        return NotificationType.bookmark;
      case 'reply':
        return NotificationType.reply;
      default:
        return NotificationType.comment;
    }
  }

  /// 표시용 텍스트 생성
  String getDisplayText(String fromNickName) {
    switch (this) {
      case NotificationType.comment:
        return '$fromNickName님이 댓글을 남겼습니다';
      case NotificationType.bookmark:
        return '$fromNickName님이 북마크했습니다';
      case NotificationType.reply:
        return '$fromNickName님이 대댓글을 남겼습니다';
    }
  }
}
