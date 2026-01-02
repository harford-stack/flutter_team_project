// lib/models/notification_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String postId;
  final String? commentId;
  final String fromUserId;
  final String fromNickName;
  final NotificationType type;  // 이거 없으면 판단 로직이 복잡하고 실용적으로 봤을 때도 문제(후속 알림 범위가 넓히는등)가 있어서 이것을 일단 넣었습니다.
  final String? commentContent; //
  final bool isRead;
  final DateTime cdate;

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

// 알림 유형 나열
enum NotificationType {
  comment,
  bookmark,
  reply;

  @override
  String toString() {
    return name;
  }

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