import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// 커뮤니티 테스트 데이터 추가 스크립트
/// 
/// 사용 방법:
/// 1. Firebase Storage에 이미지를 업로드하고 URL을 복사
/// 2. 아래의 testPosts 리스트에 데이터 추가
/// 3. main() 함수 실행
/// 
/// 예시:
/// ```dart
/// void main() async {
///   final script = AddTestPostsScript();
///   await script.addTestPosts();
/// }
/// ```

class AddTestPostsScript {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Firestore에서 가져온 실제 사용자 목록
  List<Map<String, String>>? _realUsers;

  /// gs:// 형식 URL을 HTTP 다운로드 URL로 변환
  /// gs:// 형식: gs://[버킷이름]/[파일경로]
  /// HTTP 형식: https://firebasestorage.googleapis.com/v0/b/[버킷이름]/o/[인코딩된경로]?alt=media
  Future<String> _convertGsUrlToHttp(String gsUrl) async {
    try {
      // gs:// 형식인지 확인
      if (gsUrl.startsWith('gs://')) {
        // gs://flutterteamproject-ae948.firebasestorage.app/posts/... 형식
        final uri = Uri.parse(gsUrl.replaceFirst('gs://', 'https://'));
        final pathParts = uri.path.split('/');
        
        if (pathParts.length >= 2) {
          // 버킷 이름과 파일 경로 추출
          final bucketName = pathParts[1].replaceAll('.firebasestorage.app', '.appspot.com');
          final filePath = pathParts.sublist(2).join('/');
          
          // 파일 경로 URL 인코딩
          final encodedPath = Uri.encodeComponent(filePath);
          
          // HTTP 다운로드 URL 생성
          final httpUrl = 'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/$encodedPath?alt=media';
          
          // URL이 유효한지 확인 (실제로는 Storage에서 getDownloadURL 사용 권장)
          // 여기서는 기본 형식으로 변환만 수행
          return httpUrl;
        }
      }
      
      // 이미 HTTP URL이거나 다른 형식이면 그대로 반환
      return gsUrl;
    } catch (e) {
      print('URL 변환 실패: $e');
      return gsUrl; // 변환 실패 시 원본 반환
    }
  }

  /// Firebase Storage Reference에서 다운로드 URL 가져오기 (권장 방법)
  Future<String> _getDownloadUrlFromGs(String gsUrl) async {
    try {
      if (gsUrl.startsWith('gs://')) {
        // gs:// 형식에서 파일 경로 추출
        final pathMatch = RegExp(r'gs://[^/]+/(.+)').firstMatch(gsUrl);
        if (pathMatch != null) {
          final filePath = pathMatch.group(1)!;
          final ref = _storage.ref().child(filePath);
          final downloadUrl = await ref.getDownloadURL();
          return downloadUrl;
        }
      }
      return gsUrl;
    } catch (e) {
      print('다운로드 URL 가져오기 실패: $e');
      return gsUrl;
    }
  }

  /// Firestore에서 실제 사용자 목록 가져오기
  Future<List<Map<String, String>>> _getRealUsers() async {
    if (_realUsers != null) {
      return _realUsers!;
    }

    try {
      print('📋 Firestore에서 사용자 목록 가져오는 중...');
      final snapshot = await _firestore.collection('users').get();
      
      _realUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, String>{
          'userId': doc.id,
          'nickName': (data['nickname'] ?? data['displayName'] ?? '익명').toString(),
        };
      }).toList();

      print('✅ 사용자 ${_realUsers!.length}명 발견:');
      for (var user in _realUsers!) {
        print('   - ${user['nickName']} (${user['userId']})');
      }
      print('');

      return _realUsers!;
    } catch (e) {
      print('❌ 사용자 목록 가져오기 실패: $e');
      return [];
    }
  }

  /// 테스트 게시글 데이터
  /// Firebase Storage에 이미지를 업로드한 후 thumbnailUrl을 여기에 추가하세요
  /// userId와 nickName은 Firestore에서 자동으로 가져옵니다
  final List<Map<String, dynamic>> testPosts = [
    {
      'title': '맛있는 파스타 레시피 공유합니다!',
      'content': '오늘 집에서 만든 크림 파스타가 정말 맛있어서 공유하고 싶어요. 재료는 간단한데 결과물은 레스토랑 수준이에요!',
      'category': '자유게시판',
      'thumbnailUrl': 'gs://flutterteamproject-ae948.firebasestorage.app/posts/appTestImage5.jpg', // Firebase Storage URL을 여기에 입력하세요
      'hasComments': true, // 댓글 추가 여부
      'hasReplies': true, // 대댓글 추가 여부
      'bookmarkUserIndexes': [1, 2], // 북마크할 사용자 인덱스 (실제 사용자 목록에서 순서대로)
    },
    {
      'title': '김치찌개 만드는 법 질문드려요',
      'content': '김치찌개를 만들 때 물을 얼마나 넣어야 할까요? 항상 너무 싱거워지거나 너무 짜게 되는데...',
      'category': '문의사항',
      'thumbnailUrl': 'gs://flutterteamproject-ae948.firebasestorage.app/posts/appTestImage6.jpg', // Firebase Storage URL을 여기에 입력하세요
      'hasComments': true,
      'hasReplies': false,
      'bookmarkUserIndexes': [0], // 첫 번째 사용자가 북마크
    },
    {
      'title': '간단한 아침식사 추천',
      'content': '바쁜 아침에 빠르게 만들 수 있는 영양만점 아침식사 레시피를 공유합니다. 토스트와 계란만으로도 충분해요!',
      'category': '자유게시판',
      'thumbnailUrl': 'gs://flutterteamproject-ae948.firebasestorage.app/posts/appTestImage7.jpg', // Firebase Storage URL을 여기에 입력하세요
      'hasComments': true,
      'hasReplies': true,
      'bookmarkUserIndexes': [0, 1], // 첫 번째, 두 번째 사용자가 북마크
    },
    {
      'title': '제철 과일로 만든 디저트',
      'content': '딸기 시즌이라 딸기 케이크를 만들었어요. 레시피는 아래에 자세히 적어놓았습니다.',
      'category': '자유게시판',
      'thumbnailUrl': 'gs://flutterteamproject-ae948.firebasestorage.app/posts/appTestImage8.jpg', // Firebase Storage URL을 여기에 입력하세요
      'hasComments': false,
      'hasReplies': false,
      'bookmarkUserIndexes': [], // 북마크 없음
    },
    {
      'title': '집에서 만든 수제 피자 도전기',
      'content': '피자집에서 먹는 것보다 집에서 만든 피자가 더 맛있을 수 있다는 걸 알게 되었어요! 도우부터 토핑까지 직접 만들었습니다.',
      'category': '자유게시판',
      'thumbnailUrl': 'gs://flutterteamproject-ae948.firebasestorage.app/posts/appTestImage9.jpg', // Firebase Storage URL을 여기에 입력하세요
      'hasComments': true,
      'hasReplies': false,
      'bookmarkUserIndexes': [0, 2],
    },
    {
      'title': '비건 레시피 추천 부탁드려요',
      'content': '채식 위주로 식단을 바꾸려고 하는데, 맛있고 영양가 있는 비건 레시피가 있을까요? 특히 단백질 섭취가 걱정됩니다.',
      'category': '문의사항',
      'thumbnailUrl': 'gs://flutterteamproject-ae948.firebasestorage.app/posts/appTestImage10.jpg', // Firebase Storage URL을 여기에 입력하세요
      'hasComments': true,
      'hasReplies': true,
      'bookmarkUserIndexes': [1],
    },
    {
      'title': '한식 레시피 모음 - 간단한 반찬들',
      'content': '집에서 쉽게 만들 수 있는 한식 반찬 레시피를 정리했습니다. 나물, 볶음, 조림 등 다양한 메뉴가 있어요!',
      'category': '자유게시판',
      'thumbnailUrl': 'gs://flutterteamproject-ae948.firebasestorage.app/posts/appTestImage11.jpg', // Firebase Storage URL을 여기에 입력하세요
      'hasComments': true,
      'hasReplies': false,
      'bookmarkUserIndexes': [0, 1, 2],
    },
    {
      'title': '베이킹 초보를 위한 쿠키 레시피',
      'content': '처음 베이킹을 시작하는 분들을 위한 초간단 쿠키 레시피입니다. 실패 확률이 거의 없어요!',
      'category': '자유게시판',
      'thumbnailUrl': 'gs://flutterteamproject-ae948.firebasestorage.app/posts/appTestImage12.jpg', // Firebase Storage URL을 여기에 입력하세요
      'hasComments': false,
      'hasReplies': false,
      'bookmarkUserIndexes': [],
    },
  ];

  /// 테스트 댓글 내용 (실제 사용자 정보는 자동으로 사용)
  final List<String> testCommentContents = [
    '정말 맛있어 보이네요! 레시피 감사합니다.',
    '저도 한번 만들어볼게요. 좋은 정보 감사합니다!',
    '사진만 봐도 맛있을 것 같아요. 다음에 저도 도전해볼게요!',
  ];

  /// 테스트 대댓글 내용
  final List<String> testReplyContents = [
    '감사합니다! 궁금한 점 있으면 언제든 물어보세요.',
    '네, 도움이 되었다니 다행이에요!',
  ];

  /// 테스트 게시글 추가
  Future<void> addTestPosts() async {
    print('🚀 테스트 게시글 추가 시작...\n');

    // 1. 실제 사용자 목록 가져오기
    final users = await _getRealUsers();
    if (users.isEmpty) {
      print('❌ 사용자가 없습니다. 먼저 사용자를 등록해주세요.');
      return;
    }

    for (int i = 0; i < testPosts.length; i++) {
      final postData = testPosts[i];
      
      var thumbnailUrl = postData['thumbnailUrl'] as String? ?? '';
      
      if (thumbnailUrl.isEmpty) {
        print('⚠️  게시글 ${i + 1}: thumbnailUrl이 비어있습니다. 스킵합니다.');
        continue;
      }

      try {
        // gs:// 형식이면 HTTP URL로 변환
        if (thumbnailUrl.startsWith('gs://')) {
          print('   🔄 gs:// URL을 HTTP URL로 변환 중...');
          thumbnailUrl = await _getDownloadUrlFromGs(thumbnailUrl);
          print('   ✅ 변환 완료: $thumbnailUrl');
        }

        // 작성자 선택 (순환 사용)
        final authorIndex = i % users.length;
        final author = users[authorIndex];

        // 2. 게시글 추가
        final postRef = await _firestore.collection('post').add({
          'title': postData['title'],
          'content': postData['content'],
          'category': postData['category'],
          'userId': author['userId']!,
          'nickName': author['nickName']!,
          'commentCount': 0, // 댓글 추가 후 업데이트
          'bookmarkCount': 0, // 북마크 추가 후 업데이트
          'thumbnailUrl': thumbnailUrl,
          'imageUrls': [thumbnailUrl],
          'cdate': Timestamp.now(),
          'udate': null,
        });

        final postId = postRef.id;
        print('✅ 게시글 ${i + 1} 추가 완료: $postId (작성자: ${author['nickName']})');

        int commentCount = 0;

        // 3. 댓글 추가
        if (postData['hasComments'] == true) {
          for (int j = 0; j < testCommentContents.length && j < users.length; j++) {
            // 댓글 작성자 선택 (작성자 제외)
            final commenterIndex = (authorIndex + j + 1) % users.length;
            final commenter = users[commenterIndex];

            final commentRef = await _firestore
                .collection('post')
                .doc(postId)
                .collection('comment')
                .add({
              'postId': postId,
              'content': testCommentContents[j],
              'userId': commenter['userId']!,
              'nickName': commenter['nickName']!,
              'pComment': null, // 일반 댓글
              'cdate': Timestamp.now(),
              'udate': null,
            });

            commentCount++;
            final commentId = commentRef.id;

            // 4. 대댓글 추가 (첫 번째 댓글에만)
            if (postData['hasReplies'] == true && j == 0) {
              for (int k = 0; k < testReplyContents.length && k < users.length; k++) {
                // 대댓글 작성자 선택
                final replyIndex = (commenterIndex + k + 1) % users.length;
                final replier = users[replyIndex];

                await _firestore
                    .collection('post')
                    .doc(postId)
                    .collection('comment')
                    .add({
                  'postId': postId,
                  'content': testReplyContents[k],
                  'userId': replier['userId']!,
                  'nickName': replier['nickName']!,
                  'pComment': commentId, // 부모 댓글 ID
                  'cdate': Timestamp.now(),
                  'udate': null,
                });
                commentCount++;
              }
            }
          }

          // 댓글 수 업데이트
          await _firestore.collection('post').doc(postId).update({
            'commentCount': commentCount,
          });
          print('   💬 댓글 ${commentCount}개 추가 완료');
        }

        // 5. 북마크 추가
        if (postData['bookmarkUserIndexes'] != null && 
            (postData['bookmarkUserIndexes'] as List).isNotEmpty) {
          int bookmarkCount = 0;
          final bookmarkIndexes = postData['bookmarkUserIndexes'] as List<int>;
          
          for (var userIndex in bookmarkIndexes) {
            if (userIndex >= 0 && userIndex < users.length) {
              final bookmarker = users[userIndex];
              final userId = bookmarker['userId']!;

              // 북마크 중복 확인
              final existingBookmark = await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('UserBookmark')
                  .where('postId', isEqualTo: postId)
                  .get();

              if (existingBookmark.docs.isEmpty) {
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('UserBookmark')
                    .add({
                  'postId': postId,
                  'category': postData['category'],
                  'title': postData['title'],
                  'nickName': author['nickName']!,
                  'cdate': Timestamp.now(),
                  'thumbnailUrl': postData['thumbnailUrl'],
                });
                bookmarkCount++;
              }
            }
          }

          // 북마크 수 업데이트
          if (bookmarkCount > 0) {
            await _firestore.collection('post').doc(postId).update({
              'bookmarkCount': FieldValue.increment(bookmarkCount),
            });
            print('   📚 북마크 ${bookmarkCount}개 추가 완료');
          }
        }

        print('');
      } catch (e) {
        print('❌ 게시글 ${i + 1} 추가 실패: $e\n');
      }
    }

    print('✨ 테스트 게시글 추가 완료!');
  }

  /// 특정 게시글에만 댓글/대댓글 추가
  Future<void> addCommentsToPost(String postId, {
    int commentCount = 3,
    bool addReplies = true,
  }) async {
    try {
      print('💬 게시글 $postId에 댓글 추가 중...');

      // 실제 사용자 목록 가져오기
      final users = await _getRealUsers();
      if (users.isEmpty) {
        print('❌ 사용자가 없습니다.');
        return;
      }

      // 게시글 작성자 확인
      final postDoc = await _firestore.collection('post').doc(postId).get();
      if (!postDoc.exists) {
        print('❌ 게시글을 찾을 수 없습니다');
        return;
      }
      final postData = postDoc.data()!;
      final authorId = postData['userId'] as String;
      final authorIndex = users.indexWhere((u) => u['userId'] == authorId);

      int totalCount = 0;

      for (int i = 0; i < commentCount && i < testCommentContents.length && i < users.length; i++) {
        // 댓글 작성자 선택 (작성자 제외)
        final commenterIndex = authorIndex >= 0 
            ? (authorIndex + i + 1) % users.length
            : i % users.length;
        final commenter = users[commenterIndex];

        final commentRef = await _firestore
            .collection('post')
            .doc(postId)
            .collection('comment')
            .add({
          'postId': postId,
          'content': testCommentContents[i],
          'userId': commenter['userId']!,
          'nickName': commenter['nickName']!,
          'pComment': null,
          'cdate': Timestamp.now(),
          'udate': null,
        });

        totalCount++;
        final commentId = commentRef.id;

        // 대댓글 추가
        if (addReplies && i == 0) {
          for (int j = 0; j < testReplyContents.length && j < users.length; j++) {
            final replyIndex = (commenterIndex + j + 1) % users.length;
            final replier = users[replyIndex];

            await _firestore
                .collection('post')
                .doc(postId)
                .collection('comment')
                .add({
              'postId': postId,
              'content': testReplyContents[j],
              'userId': replier['userId']!,
              'nickName': replier['nickName']!,
              'pComment': commentId,
              'cdate': Timestamp.now(),
              'udate': null,
            });
            totalCount++;
          }
        }
      }

      // 댓글 수 업데이트
      await _firestore.collection('post').doc(postId).update({
        'commentCount': FieldValue.increment(totalCount),
      });

      print('✅ 댓글 ${totalCount}개 추가 완료');
    } catch (e) {
      print('❌ 댓글 추가 실패: $e');
    }
  }

  /// 특정 게시글에 북마크 추가
  Future<void> addBookmarkToPost(String postId, List<String> userIds) async {
    try {
      print('📚 게시글 $postId에 북마크 추가 중...');

      // 게시글 정보 가져오기
      final postDoc = await _firestore.collection('post').doc(postId).get();
      if (!postDoc.exists) {
        print('❌ 게시글을 찾을 수 없습니다');
        return;
      }

      final postData = postDoc.data()!;
      int bookmarkCount = 0;

      for (var userId in userIds) {
        // 북마크 중복 확인
        final existingBookmark = await _firestore
            .collection('users')
            .doc(userId)
            .collection('UserBookmark')
            .where('postId', isEqualTo: postId)
            .get();

        if (existingBookmark.docs.isEmpty) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('UserBookmark')
              .add({
            'postId': postId,
            'category': postData['category'],
            'title': postData['title'],
            'nickName': postData['nickName'],
            'cdate': Timestamp.now(),
            'thumbnailUrl': postData['thumbnailUrl'] ?? '',
          });
          bookmarkCount++;
        }
      }

      // 북마크 수 업데이트
      if (bookmarkCount > 0) {
        await _firestore.collection('post').doc(postId).update({
          'bookmarkCount': FieldValue.increment(bookmarkCount),
        });
        print('✅ 북마크 ${bookmarkCount}개 추가 완료');
      } else {
        print('⚠️  추가된 북마크가 없습니다 (이미 북마크한 사용자)');
      }
    } catch (e) {
      print('❌ 북마크 추가 실패: $e');
    }
  }
}

