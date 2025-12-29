// lib/services/comment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  /// comment list를 가져오기
  Future<List<Comment>> getComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .orderBy('cdate', descending: false)  // 按时间升序
          .get();

      return snapshot.docs
          .map((doc) => Comment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('获取评论失败: $e');
      return [];
    }
  }

  /// 添加评论到帖子的 subcollection
  Future<bool> addComment({
    required String postId,      // 帖子ID
    required String userId,      // 评论者ID
    required String nickName,    // 评论者昵称
    required String content,     // 评论内容
  }) async {
    try {
      // 创建评论数据
      final commentData = {
        'postId': postId,
        'userId': userId,
        'nickName': nickName,
        'content': content,
        'cdate': Timestamp.now(),
        'udate': null,
        'likeCount': 0,
      };

      // 添加到 subcollection
      await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')  
          .add(commentData);      

      // 同时更新帖子的评论数
      await _firestore.collection('post').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('添加评论失败: $e');
      return false;
    }
  }
  
}