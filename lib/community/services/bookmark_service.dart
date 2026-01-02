import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

/// ========================================
/// BookmarkService - 사용자 북마크 서비스
/// ========================================
///
/// 데이터 구조:
/// users/{userId}/UserBookmark/{bookmarkId}
///   ├── postId: 게시글 ID
///   ├── category: 게시글 분류
///   ├── title: 게시글 제목
///   ├── nickName: 작성자
///   ├── cdate: 북마크 날짜
///   └── thumbnailUrl: 썸네일
///
/// 기능:
/// 1. 사용자의 북마크 리스트 조회 (카테고리 필터링 지원)
/// 2. 북마크 추가/삭제
/// 3. 북마크 상태 확인
/// ========================================

class BookmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ========================================
  /// 사용자의 북마크 리스트 가져오기
  /// ========================================
  ///
  /// 파라미터:
  /// - userId: 현재 사용자 ID
  /// - category: 카테고리 필터 (null이면 전체)
  ///
  /// 리턴:
  /// - List<Post> - 북마크한 게시글 리스트 (최신순)
  ///
  /// 구현 로직:
  /// 1. users/{userId}/UserBookmark 컬렉션에서 북마크 리스트 가져오기
  /// 2. 카테고리 필터링 (프론트엔드에서 처리)
  /// 3. 각 북마크의 postId로 실제 게시글 데이터 가져오기
  /// 4. 최신순 정렬
  Future<List<Post>> getBookmarkedPosts(
      String userId, {
        String? category,
      }) async {
    try {
      print('📚 사용자 북마크 조회: $userId, 카테고리: $category');

      // ===== 1단계: UserBookmark 컬렉션에서 모든 북마크 가져오기 =====
      // ⚠️ 주의: category 필터링은 프론트엔드에서 처리
      // (Firestore where + orderBy 제약 때문)
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('UserBookmark')
          .orderBy('cdate', descending: true);  // 최신순 정렬

      final bookmarkSnapshot = await query.get();
      print('📚 북마크 ${bookmarkSnapshot.docs.length}개 발견');

      // ===== 2단계: postId로 실제 게시글 데이터 가져오기 =====
      List<Post> bookmarkedPosts = [];

      for (var bookmarkDoc in bookmarkSnapshot.docs) {
        final bookmarkData = bookmarkDoc.data() as Map<String, dynamic>;
        final postId = bookmarkData['postId'] as String?;
        final bookmarkCategory = bookmarkData['category'] as String?;

        if (postId == null) continue;

        // ===== 3단계: 카테고리 필터링 (프론트엔드) =====
        if (category != null &&
            category.isNotEmpty &&
            category != '전체' &&
            bookmarkCategory != category) {
          continue;  // 카테고리가 맞지 않으면 스킵
        }

        // Post 컬렉션에서 실제 게시글 가져오기
        final postDoc = await _firestore
            .collection('post')
            .doc(postId)
            .get();

        if (postDoc.exists) {
          bookmarkedPosts.add(Post.fromFirestore(postDoc));
        } else {
          // 게시글이 삭제된 경우 북마크도 삭제
          print('⚠️ 게시글이 삭제됨, 북마크도 삭제: $postId');
          await bookmarkDoc.reference.delete();
        }
      }

      print('✅ 북마크한 게시글 ${bookmarkedPosts.length}개 로드 완료');
      return bookmarkedPosts;
    } catch (e) {
      print('❌ 북마크 리스트 로드 실패: $e');
      return [];
    }
  }

  /// ========================================
  /// 북마크 추가
  /// ========================================
  ///
  /// 파라미터:
  /// - userId: 사용자 ID
  /// - post: 북마크할 게시글 객체
  ///
  /// 리턴:
  /// - bool - 성공 여부
  ///
  /// 구현 로직:
  /// 1. users/{userId}/UserBookmark에 새 문서 추가
  /// 2. Post 컬렉션의 bookmarkCount +1
  Future<bool> addBookmark(String userId, Post post) async {
    try {
      print('북마크 추가: userId=$userId, postId=${post.id}');

      // ===== 1단계: 이미 북마크했는지 확인 =====
      final existingBookmark = await _firestore
          .collection('users')
          .doc(userId)
          .collection('UserBookmark')
          .where('postId', isEqualTo: post.id)
          .get();

      if (existingBookmark.docs.isNotEmpty) {
        print('이미 북마크한 게시글입니다');
        return false;
      }

      // ===== 2단계: UserBookmark에 추가 =====
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('UserBookmark')
          .add({
        'postId': post.id,
        'category': post.category,
        'title': post.title,
        'nickName': post.nickName,
        'cdate': Timestamp.now(),
        'thumbnailUrl': post.thumbnailUrl,
      });

      // ===== 3단계: Post의 bookmarkCount 증가 =====
      await _firestore
          .collection('post')
          .doc(post.id)
          .update({
        'bookmarkCount': FieldValue.increment(1),
      });

      print('북마크 추가 성공');
      return true;
    } catch (e) {
      print('북마크 추가 실패: $e');
      return false;
    }
  }

  /// ========================================
  /// 북마크 삭제
  /// ========================================
  ///
  /// 파라미터:
  /// - userId: 사용자 ID
  /// - postId: 게시글 ID
  ///
  /// 리턴:
  /// - bool - 성공 여부
  Future<bool> removeBookmark(String userId, String postId) async {
    try {
      print('북마크 삭제: userId=$userId, postId=$postId');

      // ===== 1단계: UserBookmark에서 해당 북마크 찾기 =====
      final bookmarkSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('UserBookmark')
          .where('postId', isEqualTo: postId)
          .get();

      if (bookmarkSnapshot.docs.isEmpty) {
        print('북마크를 찾을 수 없습니다');
        return false;
      }

      // ===== 2단계: 북마크 문서 삭제 =====
      for (var doc in bookmarkSnapshot.docs) {
        await doc.reference.delete();
      }

      // ===== 3단계: Post의 bookmarkCount 감소 =====
      await _firestore
          .collection('post')
          .doc(postId)
          .update({
        'bookmarkCount': FieldValue.increment(-1),
      });

      print('북마크 삭제 성공');
      return true;
    } catch (e) {
      print('북마크 삭제 실패: $e');
      return false;
    }
  }

  /// ========================================
  /// 여러 개 북마크 한번에 삭제
  /// ========================================
  ///
  /// 파라미터:
  /// - userId: 사용자 ID
  /// - postIds: 삭제할 게시글 ID 리스트
  ///
  /// 리턴:
  /// - int - 성공한 개수
  Future<int> removeMultipleBookmarks(
      String userId,
      List<String> postIds,
      ) async {
    int successCount = 0;

    try {
      print('북마크 일괄 삭제: ${postIds.length}개');

      for (var postId in postIds) {
        final success = await removeBookmark(userId, postId);
        if (success) {
          successCount++;
        }
      }

      print('북마크 일괄 삭제 완료: $successCount/${postIds.length}');
      return successCount;
    } catch (e) {
      print('북마크 일괄 삭제 실패: $e');
      return successCount;
    }
  }

  /// ========================================
  /// 북마크 여부 확인
  /// ========================================
  ///
  /// 파라미터:
  /// - userId: 사용자 ID
  /// - postId: 게시글 ID
  ///
  /// 리턴:
  /// - bool - 북마크 했으면 true, 아니면 false
  Future<bool> isBookmarked(String userId, String postId) async {
    try {
      final bookmarkSnapshot = await _firestore
          .collection('users')
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
}