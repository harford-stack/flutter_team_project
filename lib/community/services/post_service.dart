// ============================================
// lib/community/services/post_service.dart
// 역할: 게시글 CRUD 및 조회
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/post_model.dart';

/// 게시글 서비스
///
/// 주요 기능:
/// 1. 게시글 목록 조회 (검색, 정렬, 필터링)
/// 2. 게시글 생성 (이미지 업로드 포함)
/// 3. 게시글 수정
/// 4. 게시글 삭제
/// 5. 내 게시글 조회
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// ========================================
  /// 게시글 목록 조회
  /// ========================================
  ///
  /// 파라미터:
  /// - searchQuery: 검색어 (제목 또는 내용에서 검색)
  /// - sortOrder: 정렬 순서 ('최신순' 또는 '인기순')
  /// - categories: 카테고리 필터 (null이면 전체)
  ///
  /// 리턴:
  /// - List<Post> - 게시글 리스트
  ///
  /// 작동 방식:
  /// 1. Firestore 쿼리 구성 (카테고리, 정렬)
  /// 2. 데이터 가져오기
  /// 3. 검색어로 클라이언트 필터링 (Firestore 검색 제약 때문)
  Future<List<Post>> getPosts({
    String? searchQuery,
    String sortOrder = '최신순',
    List<String>? categories,
  }) async {
    // ===== 1단계: 기본 쿼리 설정 =====
    Query query = _firestore.collection('post');

    // ===== 2단계: 카테고리 필터링 =====
    if (categories != null && categories.isNotEmpty) {
      query = query.where('category', whereIn: categories);
    }

    // ===== 3단계: 정렬 =====
    switch (sortOrder) {
      case '최신순':
        query = query.orderBy('cdate', descending: true);
        break;
      case '인기순':
        query = query.orderBy('bookmarkCount', descending: true);
        break;
    }

    // ===== 4단계: 쿼리 실행 =====
    final snapshot = await query.get();
    List<Post> posts = snapshot.docs
        .map((doc) => Post.fromFirestore(doc))
        .toList();

    // ===== 5단계: 검색어 필터링 (클라이언트) =====
    // Firestore의 텍스트 검색 제약으로 인해 클라이언트에서 처리
    if (searchQuery != null && searchQuery.isNotEmpty) {
      posts = posts.where((post) {
        return post.title.contains(searchQuery) ||
            post.content.contains(searchQuery);
      }).toList();
    }

    return posts;
  }

  /// ========================================
  /// 게시글 생성
  /// ========================================
  ///
  /// 파라미터:
  /// - title: 제목
  /// - content: 내용
  /// - category: 분류
  /// - userId: 사용자 ID
  /// - nickName: 사용자 닉네임
  /// - imageFile: 이미지 파일 (선택사항)
  ///
  /// 리턴:
  /// - String? - 성공 시 게시글 ID, 실패 시 null
  ///
  /// 작동 방식:
  /// 1. 이미지가 있으면 Storage에 업로드
  /// 2. 게시글 데이터 구성
  /// 3. Firestore에 문서 추가
  ///
  /// 에러 처리:
  /// - 이미지 업로드 실패 시 예외를 다시 던져서 UI에서 처리
  Future<String?> createPost({
    required String title,
    required String content,
    required String category,
    required String userId,
    required String nickName,
    File? imageFile,
  }) async {
    try {
      String thumbnailUrl = '';

      // ===== 1단계: 이미지 업로드 (있으면) =====
      if (imageFile != null) {
        try {
          thumbnailUrl = await _uploadImage(imageFile, userId);
          if (thumbnailUrl.isEmpty) {
            throw Exception('이미지 업로드에 실패했습니다');
          }
        } catch (e) {
          // 이미지 업로드 실패 시 예외를 다시 던짐
          rethrow;
        }
      }

      // ===== 2단계: 게시글 데이터 구성 =====
      final postData = {
        'title': title,
        'content': content,
        'category': category,
        'userId': userId,
        'nickName': nickName,
        'commentCount': 0,
        'bookmarkCount': 0,
        'thumbnailUrl': thumbnailUrl,
        'imageUrls': thumbnailUrl.isNotEmpty ? [thumbnailUrl] : [],
        'cdate': Timestamp.now(),
        'udate': null,
      };

      // ===== 3단계: Firestore에 추가 =====
      final docRef = await _firestore.collection('post').add(postData);

      return docRef.id;
    } catch (e) {
      rethrow; // 예외를 다시 던져서 UI에서 처리
    }
  }

  /// ========================================
  /// 게시글 수정
  /// ========================================
  ///
  /// 파라미터:
  /// - postId: 게시글 ID
  /// - title: 새 제목
  /// - content: 새 내용
  /// - category: 새 분류
  /// - newImageFile: 새 이미지 (선택사항)
  /// - deleteImage: 기존 이미지 삭제 여부
  ///
  /// 리턴:
  /// - bool - 성공 여부
  ///
  /// 작동 방식:
  /// 1. 기존 게시글 데이터 조회
  /// 2. 이미지 처리 (삭제/교체)
  /// 3. 게시글 데이터 업데이트
  Future<bool> updatePost({
    required String postId,
    required String title,
    required String content,
    required String category,
    File? newImageFile,
    bool deleteImage = false,
  }) async {
    try {
      // ===== 1단계: 기존 게시글 데이터 조회 =====
      final docSnapshot = await _firestore.collection('post').doc(postId).get();
      if (!docSnapshot.exists) {
        return false;
      }

      final oldData = docSnapshot.data()!;
      String thumbnailUrl = oldData['thumbnailUrl'] ?? '';

      // ===== 2단계: 이미지 처리 =====
      if (deleteImage && thumbnailUrl.isNotEmpty) {
        // 기존 이미지 삭제
        await _deleteImage(thumbnailUrl);
        thumbnailUrl = '';
      } else if (newImageFile != null) {
        // 기존 이미지가 있으면 삭제
        if (thumbnailUrl.isNotEmpty) {
          await _deleteImage(thumbnailUrl);
        }
        // 새 이미지 업로드
        thumbnailUrl = await _uploadImage(newImageFile, oldData['userId']);
      }

      // ===== 3단계: 게시글 데이터 업데이트 =====
      final updateData = {
        'title': title,
        'content': content,
        'category': category,
        'thumbnailUrl': thumbnailUrl,
        'imageUrls': thumbnailUrl.isNotEmpty ? [thumbnailUrl] : [],
        'udate': Timestamp.now(),
      };

      await _firestore.collection('post').doc(postId).update(updateData);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// ========================================
  /// 게시글 삭제
  /// ========================================
  ///
  /// 파라미터:
  /// - postId: 게시글 ID
  ///
  /// 리턴:
  /// - bool - 성공 여부
  ///
  /// 작동 방식:
  /// 1. 게시글 데이터 조회
  /// 2. 이미지 삭제 (있으면)
  /// 3. 모든 댓글 삭제
  /// 4. 모든 북마크 삭제
  /// 5. 게시글 문서 삭제
  Future<bool> deletePost(String postId) async {
    try {
      // ===== 1단계: 게시글 데이터 조회 =====
      final docSnapshot = await _firestore.collection('post').doc(postId).get();
      if (!docSnapshot.exists) {
        return false;
      }

      final data = docSnapshot.data()!;
      final thumbnailUrl = data['thumbnailUrl'] ?? '';

      // ===== 2단계: 이미지 삭제 (있으면) =====
      if (thumbnailUrl.isNotEmpty) {
        await _deleteImage(thumbnailUrl);
      }

      // ===== 3단계: 모든 댓글 삭제 =====
      final commentsSnapshot = await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .get();

      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // ===== 4단계: 모든 북마크 삭제 =====
      final bookmarksSnapshot = await _firestore
          .collection('post')
          .doc(postId)
          .collection('bookmarks')
          .get();

      for (var doc in bookmarksSnapshot.docs) {
        await doc.reference.delete();
      }

      // ===== 5단계: 게시글 문서 삭제 =====
      await _firestore.collection('post').doc(postId).delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// ========================================
  /// 내 게시글 조회
  /// ========================================
  ///
  /// 파라미터:
  /// - userId: 사용자 ID
  /// - category: 카테고리 필터 (선택사항)
  ///
  /// 리턴:
  /// - List<Post> - 내 게시글 리스트 (최신순)
  Future<List<Post>> getMyPosts({
    required String userId,
    String? category,
  }) async {
    try {
      // ===== 1단계: 기본 쿼리 설정 (userId 필터링) =====
      Query query = _firestore
          .collection('post')
          .where('userId', isEqualTo: userId);

      // ===== 2단계: 카테고리 필터링 (선택적) =====
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // ===== 3단계: 시간순 정렬 (최신순) =====
      query = query.orderBy('cdate', descending: true);

      // ===== 4단계: 쿼리 실행 =====
      final snapshot = await query.get();

      // ===== 5단계: Post 모델로 변환 =====
      List<Post> myPosts = snapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .toList();

      return myPosts;
    } catch (e) {
      return [];
    }
  }

  /// ========================================
  /// 보조 함수: 이미지 업로드
  /// ========================================
  ///
  /// 파라미터:
  /// - imageFile: 업로드할 이미지 파일
  /// - userId: 사용자 ID (폴더 구분용)
  ///
  /// 리턴:
  /// - String - 다운로드 URL
  ///
  /// 작동 방식:
  /// 1. 파일 존재 및 크기 확인 (10MB 제한)
  /// 2. Storage에 업로드
  /// 3. 다운로드 URL 반환
  ///
  /// 에러 처리:
  /// - 권한 오류: 'unauthorized'
  /// - 용량 초과: 'quota-exceeded'
  /// - 기타 오류: 상세 메시지와 함께 예외 발생
  Future<String> _uploadImage(File imageFile, String userId) async {
    try {
      // 파일 존재 확인
      if (!await imageFile.exists()) {
        throw Exception('파일이 존재하지 않습니다');
      }

      // 파일 크기 확인 (10MB 제한)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('이미지 크기는 10MB 이하여야 합니다');
      }

      final fileName = 'posts/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = _storage.ref().child(fileName);

      // 업로드 실행
      await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'max-age=3600',
        ),
      );

      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      if (e.code == 'unauthorized') {
        throw Exception('업로드 권한이 없습니다. Firebase Storage 규칙을 확인해주세요.');
      } else if (e.code == 'quota-exceeded') {
        throw Exception('Storage 용량이 초과되었습니다.');
      } else {
        throw Exception('이미지 업로드 실패: ${e.message}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// ========================================
  /// 보조 함수: 이미지 삭제
  /// ========================================
  ///
  /// 파라미터:
  /// - imageUrl: 삭제할 이미지 URL
  ///
  /// 작동 방식:
  /// - URL에서 Storage 경로 추출하여 삭제
  Future<void> _deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;

      // URL에서 Storage 참조 추출
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // 이미지 삭제 실패는 치명적이지 않으므로 로그만 남김
    }
  }
}