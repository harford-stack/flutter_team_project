// ============================================
// lib/community/models/comment_model.dart
// 역할: 댓글 데이터 모델
// ============================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// 댓글 데이터 모델
///
/// 설명:
/// - 이 클래스는 데이터의 "형태"만 정의
/// - UI나 비즈니스 로직은 담당하지 않음
/// - Firestore와 Dart 객체 간의 변환 담당
///
/// 필드 설명:
/// - id: 댓글 고유 ID (Firestore 문서 ID)
/// - postId: 소속된 게시글 ID
/// - pComment: 부모 댓글 ID (대댓글인 경우에만 값이 있음)
/// - content: 댓글 내용
/// - userId: 작성자 ID
/// - nickName: 작성자 닉네임
/// - cdate: 생성일시
/// - udate: 수정일시 (수정하지 않았으면 null)
class Comment {
  final String id;
  final String postId;
  final String? pComment; // null 가능 (일반 댓글은 null, 대댓글만 값이 있음)
  final String content;
  final String userId;
  final String nickName;
  final DateTime cdate;
  final DateTime? udate; // null 가능

  /// ========================================
  /// 생성자
  /// ========================================
  ///
  /// 필수 필드:
  /// - id, postId, content, userId, nickName, cdate
  ///
  /// 선택 필드:
  /// - pComment, udate (null 가능)
  Comment({
    required this.id,
    required this.postId,
    this.pComment,
    required this.content,
    required this.userId,
    required this.nickName,
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
  ///    - Timestamp: toDate()로 DateTime 변환
  ///    - null 가능 필드: 조건부 변환
  ///
  /// 주의사항:
  /// - Firestore의 Timestamp는 Dart의 DateTime이 아님
  /// - 반드시 toDate()로 변환 필요
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      pComment: data['pComment'] != null
          ? data['pComment'] as String
          : null,
      content: data['content'] ?? '',
      userId: data['userId'] ?? '',
      nickName: data['nickName'] ?? '익명',
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
  /// - Firestore에 새 댓글 추가할 때
  /// - 기존 댓글 수정할 때
  ///
  /// 주의사항:
  /// - id는 포함하지 않음 (Firestore가 자동 생성)
  /// - DateTime을 Timestamp로 변환
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'content': content,
      'pComment': pComment != null ? pComment : null,
      'userId': userId,
      'nickName': nickName,
      'cdate': Timestamp.fromDate(cdate),
      'udate': udate != null ? Timestamp.fromDate(udate!) : null,
    };
  }
}