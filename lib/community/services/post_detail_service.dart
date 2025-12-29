// lib/services/post_detail_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

/// 帖子详情页专用服务
/// 负责单个帖子的 CRUD 操作和互动功能
class PostDetailService {
  // Firestore 实例
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///============================================
  /// 1. 根据 ID 获取单个帖子详情
  ///============================================
  /// 参数: postId - 帖子的唯一标识符
  /// 返回: Post? - 找到则返回 Post 对象,找不到返回 null
  Future<Post?> getPostById(String postId) async {
    try {
      // 步骤1: 去 Firestore 的 'post' 集合里,找到 ID 为 postId 的文档
      final doc = await _firestore
          .collection('post')  // 指定集合名
          .doc(postId)         // 指定文档 ID
          .get();              // 执行查询

      // 步骤2: 检查文档是否存在
      if (doc.exists) {
        // 文档存在,使用 Post.fromFirestore() 转换成 Post 对象
        return Post.fromFirestore(doc);
      }

      // 文档不存在,返回 null
      return null;

    } catch (e) {
      // 捕获错误(比如网络问题、权限问题)
      print('获取帖子详情失败: $e');
      return null;
    }
  }


  ///============================================
  /// 3. 북마크 상태
  ///============================================
  /// 参数:
  /// - postId: 帖子 ID
  /// - isBookmarked: true=收藏, false=取消收藏
  Future<void> toggleBookmark(String postId, bool isBookmarked) async {
    try {
      await _firestore.collection('post').doc(postId).update({
        'bookmarkCount': FieldValue.increment(isBookmarked ? 1 : -1),
      });
    } catch (e) {
      print('북마크 상테 전환 실패: $e');
    }
  }



}