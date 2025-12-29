import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Comment>> getComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .orderBy('cdate', descending: false)
          .get();

      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    } catch (e) {
      print('댓글을 가져오는데 실패했습니다: $e');
      return [];
    }
  }

  Future<bool> addComment({
    required String postId,
    required String userId,
    required String nickName,
    required String content,
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
      };

      await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .add(commentData);

      await _firestore.collection('post').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('댓글 추가 실패: $e');
      return false;
    }
  }
}