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
      print('获取帖子详情失败: $e');
      return null;
    }
  }

  /// 检查用户是否已收藏此帖
  /// 参数:
  /// - postId: 帖子 ID
  /// - userId: 用户 ID
  /// 返回: bool - true=已收藏, false=未收藏
  Future<bool> isBookmarked(String postId, String userId) async {
    try {
      final doc = await _firestore
          .collection('post')
          .doc(postId)
          .collection('bookmarks')
          .doc(userId)
          .get();

      return doc.exists;
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
      bool isBookmarking,
      ) async {
    try {
      final bookmarkRef = _firestore
          .collection('post')
          .doc(postId)
          .collection('bookmarks')
          .doc(userId);

      if (isBookmarking) {
        // 添加收藏记录
        await bookmarkRef.set({
          'userId': userId,
          'createdAt': Timestamp.now(),
        });
        // 增加收藏计数
        await _firestore.collection('post').doc(postId).update({
          'bookmarkCount': FieldValue.increment(1),
        });
      } else {
        // 删除收藏记录
        await bookmarkRef.delete();
        // 减少收藏计数
        await _firestore.collection('post').doc(postId).update({
          'bookmarkCount': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      print('북마크 상태 전환 실패: $e');
      rethrow;
    }
  }
}

