// lib/notifications/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 새로운 알림을 만드는
  Future<void> createNotification({
    required String userId,       // 接收者ID
    required String postId,       // 帖子ID
    String? commentId,            // 评论ID（可选）
    required String fromUserId,   // 发送者ID
    required String fromNickName, // 发送者昵称
    String? commentContent,       // 评论内容
    required NotificationType type,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        postId: postId,
        commentId: commentId,
        fromUserId: fromUserId,
        fromNickName: fromNickName,
        commentContent: commentContent,
        type: type,
        isRead: false,
        cdate: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toFirestore());

      print('알림 전송 성공: $userId');
    } catch (e) {
      print('알림 전송 실패: $e');
    }
  }

  /// 해당 사용자의 모든 알림을
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('cdate', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList());
  }

  /// 按类型获取通知
  Stream<List<NotificationModel>> getUserNotificationsByType(
      String userId,
      NotificationType type,
      ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: type.toString())
        .orderBy('cdate', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList());
  }

  /// ✅ 新增：检查帖子是否存在
  Future<bool> checkPostExists(String postId) async {
    try {
      final doc = await _firestore
          .collection('post')
          .doc(postId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ 帖子检查失败: $e');
      return false;
    }
  }

  /// ✅ 新增：检查评论是否存在
  Future<bool> checkCommentExists(String postId, String commentId) async {
    try {
      final doc = await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .doc(commentId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ 评论检查失败: $e');
      return false;
    }
  }

  /// isRead가 false인 애를 가져옴
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 읽음
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('해당 알림을 읽었습니다: $e');
    }
  }

  /// 모두 읽음
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('모두 읽음으로 표시되었습니다: $e');
    }
  }

  /// 删除
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      print('✅ 알림 삭제 성공: $notificationId');
    } catch (e) {
      print('❌ 알림 삭제 실패: $e');
    }
  }

  /// ✅ 新增：清理无效通知（帖子已删除的通知）
  Future<int> cleanInvalidNotifications(String userId) async {
    int deletedCount = 0;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (var doc in snapshot.docs) {
        final notification = NotificationModel.fromFirestore(doc);

        // 检查帖子是否存在
        final postExists = await checkPostExists(notification.postId);

        if (!postExists) {
          // 删除无效通知
          await deleteNotification(userId, notification.id);
          deletedCount++;
        }
      }

      print('✅ 清理了 $deletedCount 个无效通知');
    } catch (e) {
      print('❌ 清理无效通知失败: $e');
    }

    return deletedCount;
  }
}