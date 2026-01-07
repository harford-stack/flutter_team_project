// ============================================
// lib/community/services/comment_service.dart
// 역할: 댓글 CRUD 관리
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

/// 댓글 서비스
///
/// 주요 기능:
/// 1. 댓글 조회 (게시글별)
/// 2. 댓글/대댓글 추가
/// 3. 댓글 삭제
class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ========================================
  /// 게시글의 모든 댓글 가져오기
  /// ========================================
  ///
  /// 파라미터:
  /// - postId: 게시글 ID
  ///
  /// 리턴:
  /// - List<Comment> - 댓글 리스트 (시간순 정렬)
  ///
  /// 정렬 방식:
  /// - cdate 오름차순 (오래된 댓글이 위로)
  Future<List<Comment>> getComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .orderBy('cdate', descending: false) // 시간 오름차순
          .get();

      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// ========================================
  /// 댓글 추가
  /// ========================================
  ///
  /// 파라미터:
  /// - postId: 게시글 ID
  /// - userId: 댓글 작성자 ID
  /// - nickName: 댓글 작성자 닉네임
  /// - content: 댓글 내용
  /// - pComment: 부모 댓글 ID (대댓글인 경우에만 값이 있음)
  ///
  /// 리턴:
  /// - String? - 성공 시 새 댓글 ID, 실패 시 null
  ///
  /// 작동 방식:
  /// 1. 댓글 데이터 구성
  /// 2. Firestore의 comment 서브컬렉션에 추가
  /// 3. 게시글의 commentCount +1
  /// 4. 새로 생성된 댓글 ID 반환
  Future<String?> addComment({
    required String postId,
    required String userId,
    required String nickName,
    required String content,
    String? pComment, // 부모 댓글 ID (대댓글 작성 시 사용)
  }) async {
    try {
      // ===== 1단계: 댓글 데이터 구성 =====
      final commentData = {
        'postId': postId,
        'userId': userId,
        'nickName': nickName,
        'content': content,
        'cdate': Timestamp.now(),
        'udate': null,
        'likeCount': 0,
        'pComment': pComment, // 일반 댓글이면 null, 대댓글이면 부모 ID
      };

      // ===== 2단계: Firestore에 댓글 추가 =====
      final docRef = await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .add(commentData);

      // ===== 3단계: 게시글의 댓글 수 증가 =====
      await _firestore.collection('post').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      return docRef.id; // 새로 생성된 댓글 ID 반환
    } catch (e) {
      return null; // 실패 시 null 반환
    }
  }

  /// ========================================
  /// 댓글 삭제
  /// ========================================
  ///
  /// 파라미터:
  /// - postId: 게시글 ID
  /// - commentId: 삭제할 댓글 ID
  ///
  /// 리턴:
  /// - bool - 성공 여부
  ///
  /// 작동 방식:
  /// 1. 댓글 문서 삭제
  /// 2. 게시글의 commentCount -1
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      // 댓글 문서 삭제
      await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .doc(commentId)
          .delete();

      // 게시글 댓글 수 감소
      await _firestore.collection('post').doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}