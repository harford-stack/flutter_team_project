// ========================================
// comment_service.dart
// ========================================
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///게시글의 모든 댓글 가져오기
  Future<List<Comment>> getComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .orderBy('cdate', descending: false) // 按时间升序（早的在前）
          .get();

      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    } catch (e) {
      print('댓글을 가져오는데 실패했습니다: $e');
      return [];
    }
  }

  /// ✅ 修改：댓글 추가 - 返回新评论ID
  /// 返回值：String? (成功返回评论ID，失败返回null)
  Future<String?> addComment({
    required String postId,
    required String userId,
    required String nickName,
    required String content,
    String? pComment, // 父评论 ID（回复时使用）
  }) async {
    try {
      final commentData = {
        'postId': postId,
        'userId': userId,
        'nickName': nickName,
        'content': content,
        'cdate': Timestamp.now(),
        'udate': null,
        'likeCount': 0,
        'pComment': pComment, // 如果是回复，存储父评论 ID
      };

      // ✅ 修改：获取 DocumentReference
      final docRef = await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .add(commentData);

      // 增加帖子的评论计数
      await _firestore.collection('post').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      print('✅ 댓글 추가 성공: ${docRef.id}');
      return docRef.id;  // ✅ 返回新评论ID
    } catch (e) {
      print('❌ 댓글 추가 실패: $e');
      return null;  // ✅ 失败返回null
    }
  }

  /// deleteComment - 댓글 삭제
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      // 删除评论文档
      await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .doc(commentId)
          .delete();

      // 减少帖子的评论计数
      await _firestore.collection('post').doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('댓글 삭제 실패: $e');
      return false;
    }
  }
}