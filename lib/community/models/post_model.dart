// ============================================
// lib/community/models/post_model.dart
// 역할: 게시글 데이터 모델
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// 게시글 데이터 모델
///
/// 설명:
/// - 이 클래스는 데이터의 "형태"만 정의
/// - UI나 비즈니스 로직은 담당하지 않음
/// - Firestore와 Dart 객체 간의 변환 담당
///
/// 필드 설명:
/// - id: 게시글 고유 ID (Firestore 문서 ID)
/// - title: 제목
/// - content: 내용
/// - category: 분류 (자유게시판, 문의사항 등)
/// - userId: 작성자 ID
/// - nickName: 작성자 닉네임
/// - commentCount: 댓글 수
/// - bookmarkCount: 북마크 수
/// - thumbnailUrl: 썸네일 이미지 URL
/// - cdate: 생성일시
/// - udate: 수정일시 (수정하지 않았으면 null)
class Post {
  final String id;
  final String title;
  final String content;
  final String category;
  final String userId;
  final String nickName;
  final int commentCount;
  final int bookmarkCount;
  final String thumbnailUrl;
  final DateTime cdate;
  final DateTime? udate; // null 가능

  /// ========================================
  /// 생성자
  /// ========================================
  ///
  /// 필수 필드:
  /// - Post 객체를 만들 때 반드시 제공해야 하는 필드들
  /// - required 키워드가 붙은 필드들
  ///
  /// 선택 필드:
  /// - udate (수정일시는 처음에는 없을 수 있음)
  ///
  /// 주의사항:
  /// - 여기서 "필수"는 Dart 객체 생성 시의 필수
  /// - Firestore에 저장될 때의 필수 여부와는 별개
  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.userId,
    required this.nickName,
    required this.commentCount,
    required this.bookmarkCount,
    required this.thumbnailUrl,
    required this.cdate,
    this.udate,
  });

  /// ========================================
  /// Firestore → Dart 객체 변환
  /// ========================================
  ///
  /// 작동 방식:
  /// 1. Firestore 문서(DocumentSnapshot)를 받음
  /// 2. 문서 데이터를 Map으로 변환
  /// 3. 각 필드를 적절한 타입으로 변환
  ///    - String 필드: ?? ''로 기본값 처리
  ///    - int 필드: ?? 0으로 기본값 처리
  ///    - Timestamp: toDate()로 DateTime 변환
  ///    - null 가능 필드: 조건부 변환
  ///
  /// 주의사항:
  /// - Firestore의 Timestamp는 Dart의 DateTime이 아님
  /// - 반드시 toDate()로 변환 필요
  ///
  /// factory 키워드:
  /// - 일반 생성자와 다르게 항상 새 객체를 만들지 않을 수 있음
  /// - 캐싱이나 싱글톤 패턴에 사용 가능
  /// - 여기서는 Firestore 문서를 Post 객체로 변환하는 "공장" 역할
  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Post(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      userId: data['userId'] ?? '',
      nickName: data['nickName'] ?? '익명',
      commentCount: data['commentCount'] ?? 0,
      bookmarkCount: data['bookmarkCount'] ?? 0,
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      cdate: (data['cdate'] as Timestamp).toDate(),
      udate: data['udate'] != null
          ? (data['udate'] as Timestamp).toDate()
          : null,
    );
  }

  /// ========================================
  /// Dart 객체 → Map 변환
  /// ========================================
  ///
  /// 사용처:
  /// - Firestore에 새 게시글 추가할 때
  /// - 기존 게시글 수정할 때
  ///
  /// 주의사항:
  /// - id는 포함하지 않음 (Firestore가 자동 생성)
  /// - DateTime을 Timestamp로 변환
  ///
  /// 변환 이유:
  /// - Firestore는 Dart의 DateTime을 직접 저장 못함
  /// - Timestamp로 변환해야 Firestore에 저장 가능
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'userId': userId,
      'nickName': nickName,
      'commentCount': commentCount,
      'bookmarkCount': bookmarkCount,
      'thumbnailUrl': thumbnailUrl,
      'cdate': Timestamp.fromDate(cdate),
      'udate': udate != null ? Timestamp.fromDate(udate!) : null,
    };
  }
}