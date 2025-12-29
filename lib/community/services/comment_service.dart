// lib/services/comment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentService{
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;

  // Future<bool> addComment({
  //   required String postId,      // 帖子ID
  //   required String userId,      // 评论者ID
  //   required String nickName,    // 评论者昵称
  //   required String content,     // 评论内容
  // }) async {
  //   try {
  //     // 创建评论数据
  //     final commentData = {
  //       'postId': postId,
  //       'userId': userId,
  //       'nickName': nickName,
  //       'content': content,
  //       'cdate': Timestamp.now(),
  //       'udate': null,
  //       'likeCount': 0,
  //     };


}