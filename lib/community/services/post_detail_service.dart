// ========================================
// post_detail_service.dart
// ========================================
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

/// 帖子详情页专用服务
/// 负责单个帖子的 CRUD 操作和互动功能
class PostDetailService {
  // Firestore 实例
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 根据 ID 获取单个帖子详情
  /// 参数: postId - 帖子的唯一标识符
  /// 返回: Post? - 找到则返回 Post 对象,找不到返回 null
  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _firestore
          .collection('post')
          .doc(postId)
          .get();

      if (doc.exists) {
        return Post.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('게시글 조회 실패: $e');
      return null;
    }
  }

  /// 检查用户是否已收藏此帖
  Future<bool> isBookmarked(String postId, String userId) async {
    try {
      final bookmarkSnapshot = await _firestore
          .collection('users')  // 改这里
          .doc(userId)
          .collection('UserBookmark')
          .where('postId', isEqualTo: postId)
          .get();

      return bookmarkSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('북마크 상태 확인 실패: $e');
      return false;
    }
  }

  /// 切换收藏状态
  /// 参数:
  /// - postId: 帖子 ID
  /// - userId: 用户 ID
  /// - isBookmarking: true=收藏, false=取消收藏
  Future<void> toggleBookmark(
      String postId,
      String userId,
      Post post,
      bool isBookmarking,
      ) async {
    try {
      print('북마크 토글: postId=$postId, userId=$userId, isBookmarking=$isBookmarking');

      if (isBookmarking) {
        // ===== 收藏：添加到 users/{userId}/UserBookmark =====

        // 1. 检查是否已经收藏
        final existingBookmark = await _firestore
            .collection('users')  // 改这里
            .doc(userId)
            .collection('UserBookmark')
            .where('postId', isEqualTo: postId)
            .get();

        if (existingBookmark.docs.isEmpty) {
          // 2. 添加新的 UserBookmark 文档
          await _firestore
              .collection('users')  // 改这里
              .doc(userId)
              .collection('UserBookmark')
              .add({
            'postId': postId,
            'category': post.category,
            'title': post.title,
            'nickName': post.nickName,
            'cdate': Timestamp.now(),
            'thumbnailUrl': post.thumbnailUrl,
          });

          // 3. 增加 Post 的 bookmarkCount
          await _firestore.collection('post').doc(postId).update({
            'bookmarkCount': FieldValue.increment(1),
          });

          print('북마크 추가 성공');
        }
      } else {
        // ===== 取消收藏：从 users/{userId}/UserBookmark 删除 =====

        // 1. 查找该用户的这个 postId 的 bookmark
        final bookmarkSnapshot = await _firestore
            .collection('users')  // 改这里
            .doc(userId)
            .collection('UserBookmark')
            .where('postId', isEqualTo: postId)
            .get();

        // 2. 删除找到的 bookmark 文档
        for (var doc in bookmarkSnapshot.docs) {
          await doc.reference.delete();
        }

        // 3. 减少 Post 的 bookmarkCount
        if (bookmarkSnapshot.docs.isNotEmpty) {
          await _firestore.collection('post').doc(postId).update({
            'bookmarkCount': FieldValue.increment(-1),
          });

          print('북마크 삭제 성공');
        }
      }
    } catch (e) {
      print('북마크 상태 전환 실패: $e');
      rethrow;
    }
  }

}
