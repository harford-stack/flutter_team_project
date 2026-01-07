// ============================================
// lib/community/services/post_detail_service.dart
// 역할: 게시글 상세 조회 및 북마크 처리
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

/// 게시글 상세 서비스
///
/// 주요 기능:
/// 1. 게시글 상세 정보 조회
/// 2. 북마크 상태 확인
/// 3. 북마크 추가/삭제
class PostDetailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ========================================
  /// ID로 게시글 조회
  /// ========================================
  ///
  /// 파라미터:
  /// - postId: 게시글 ID
  ///
  /// 리턴:
  /// - Post? - 게시글 객체 (없으면 null)
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
      return null;
    }
  }

  /// ========================================
  /// 북마크 상태 확인
  /// ========================================
  ///
  /// 파라미터:
  /// - postId: 게시글 ID
  /// - userId: 사용자 ID
  ///
  /// 리턴:
  /// - bool - 북마크 했으면 true, 아니면 false
  Future<bool> isBookmarked(String postId, String userId) async {
    try {
      final bookmarkSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('UserBookmark')
          .where('postId', isEqualTo: postId)
          .get();

      return bookmarkSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// ========================================
  /// 북마크 토글
  /// ========================================
  ///
  /// 파라미터:
  /// - postId: 게시글 ID
  /// - userId: 사용자 ID
  /// - post: 게시글 객체
  /// - isBookmarking: true=추가, false=삭제
  ///
  /// 작동 방식:
  /// 1. isBookmarking=true:
  ///    - 중복 확인 후 UserBookmark에 문서 추가
  ///    - Post의 bookmarkCount +1
  /// 2. isBookmarking=false:
  ///    - UserBookmark에서 문서 삭제
  ///    - Post의 bookmarkCount -1
  Future<void> toggleBookmark(
      String postId,
      String userId,
      Post post,
      bool isBookmarking,
      ) async {
    try {
      if (isBookmarking) {
        // ===== 북마크 추가 =====

        // 1단계: 중복 확인
        final existingBookmark = await _firestore
            .collection('users')
            .doc(userId)
            .collection('UserBookmark')
            .where('postId', isEqualTo: postId)
            .get();

        if (existingBookmark.docs.isEmpty) {
          // 2단계: UserBookmark 문서 추가
          await _firestore
              .collection('users')
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

          // 3단계: Post의 bookmarkCount 증가
          await _firestore.collection('post').doc(postId).update({
            'bookmarkCount': FieldValue.increment(1),
          });
        }
      } else {
        // ===== 북마크 삭제 =====

        // 1단계: 해당 북마크 문서 찾기
        final bookmarkSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('UserBookmark')
            .where('postId', isEqualTo: postId)
            .get();

        // 2단계: 북마크 문서 삭제
        for (var doc in bookmarkSnapshot.docs) {
          await doc.reference.delete();
        }

        // 3단계: Post의 bookmarkCount 감소
        if (bookmarkSnapshot.docs.isNotEmpty) {
          await _firestore.collection('post').doc(postId).update({
            'bookmarkCount': FieldValue.increment(-1),
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}