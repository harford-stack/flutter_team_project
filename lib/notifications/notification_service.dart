// ==================================================================================
// 3. notification_service.dart - 알림 서비스
// ==================================================================================
// lib/notifications/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_model.dart';

/// 알림 서비스
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// =====================================================================================
  /// 알림 생성
  /// =====================================================================================
  /// 새 알림 생성
  Future<void> createNotification({
    required String userId,
    required String postId,
    String? commentId,
    required String fromUserId,
    required String fromNickName,
    String? commentContent,
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

  /// =====================================================================================
  /// 알림 조회
  /// =====================================================================================
  /// 사용자의 모든 알림 스트림
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

  /// 타입별 알림 스트림
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

  /// 타입별 미읽음 알림 수 스트림
  Stream<int> getUnreadCountByType(String userId, NotificationType type) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: type.toString())
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// =====================================================================================
  /// 유효성 검사
  /// =====================================================================================
  /// 게시글 존재 여부 확인
  Future<bool> checkPostExists(String postId) async {
    try {
      final doc = await _firestore.collection('post').doc(postId).get();
      return doc.exists;
    } catch (e) {
      print(' 게시글 확인 실패: $e');
      return false;
    }
  }

  // 댓글 존재 여부 확인
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
      print('댓글 확인 실패: $e');
      return false;
    }
  }

  /// =====================================================================================
  /// 읽음 처리
  /// =====================================================================================
  /// 미읽음 알림 수 스트림
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 알림 읽음 처리
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('읽음 처리 실패: $e');
    }
  }

  /// 모든 알림 읽음 처리
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
      print('전체 읽음 처리 실패: $e');
    }
  }

  /// =====================================================================================
  /// 삭제
  /// =====================================================================================
  /// 알림 삭제
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      print('알림 삭제 성공: $notificationId');
    } catch (e) {
      print('알림 삭제 실패: $e');
    }
  }

  /// 무효 알림 정리 (삭제된 게시글의 알림 제거)
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

        // 게시글 존재 확인
        final postExists = await checkPostExists(notification.postId);

        if (!postExists) {
          // 무효 알림 삭제
          await deleteNotification(userId, notification.id);
          deletedCount++;
        }
      }

      print('$deletedCount개의 무효 알림 정리 완료');
    } catch (e) {
      print('무효 알림 정리 실패: $e');
    }

    return deletedCount;
  }
}
