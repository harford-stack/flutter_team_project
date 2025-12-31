// ========================================
// comment_service.dart
// ========================================
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';



/// ========================================
/// CommentService - 댓글 관리 서비스
/// ========================================
///
/// 역할:
/// 1. 게시글의 모든 댓글 조회 (주 댓글 + 답글)
/// 2. 댓글 추가 (주 댓글 또는 답글)
/// 3. 댓글 삭제
///
/// 특징:
/// - 평면적 저장 구조 사용 (모든 댓글을 같은 레벨에 저장)
/// - pComment 필드로 부모-자식 관계 표현
/// - 프론트엔드에서 트리 구조 생성
/// ========================================
/// 评论服务
/// 负责评论的 CRUD 操作

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 获取帖子的所有评论（包括主评论和回复）
  /// 参数: postId - 帖子 ID
  /// 返回: List<Comment> - 评论列表，按创建时间升序排列
  ///


  /// ========================================
  /// getComments - 게시글의 모든 댓글 가져오기
  /// ========================================
  ///
  /// 파라미터:
  /// - postId: 게시글 ID
  ///
  /// 리턴:
  /// - List<Comment>: 댓글 리스트 (시간 오름차순 정렬)
  ///
  /// 동작 방식:
  /// 1. post/{postId}/comment 컬렉션에서 모든 댓글 조회
  /// 2. cdate 필드 기준으로 오름차순 정렬 (오래된 것이 먼저)
  /// 3. 주 댓글과 답글을 구분하지 않고 모두 반환
  /// 4. UI에서 pComment 필드를 보고 트리 구조 생성
  ///
  /// 주의사항:
  /// - 삭제된 게시글의 댓글은 자동으로 삭제되지 않음
  /// - 프론트엔드에서 pComment가 null인 것을 주 댓글로 간주
  ///
  /// 예시 반환 데이터:
  /// [
  ///   {id: "c1", pComment: null, content: "주 댓글1"},
  ///   {id: "c2", pComment: "c1", content: "답글1-1"},
  ///   {id: "c3", pComment: "c2", content: "답글1-1-1"},  ← 다층 중첩
  /// ]
  /// ========================================
  ///
  Future<List<Comment>> getComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .orderBy('cdate', descending: false) // 按时间升序（早的在前）
          .get();

      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    } catch (e) {
      print('댓글을 가져오는데 실패했습니다: $e');
      return [];
    }
  }

  /// ========================================
  /// addComment - 댓글 추가 (주 댓글 또는 답글)
  /// ========================================
  ///
  /// 파라미터:
  /// - postId: 게시글 ID
  /// - userId: 작성자 ID
  /// - nickName: 작성자 닉네임
  /// - content: 댓글 내용
  /// - pComment: 부모 댓글 ID (답글인 경우만, 주 댓글은 null)
  ///
  /// 리턴:
  /// - bool: 성공 시 true, 실패 시 false
  ///
  /// 동작 방식:
  /// 1. 댓글 데이터 객체 생성
  /// 2. post/{postId}/comment 컬렉션에 새 문서 추가
  /// 3. post/{postId}의 commentCount 필드를 +1 증가
  ///
  /// 주 댓글 vs 답글 구분:
  /// - 주 댓글: pComment = null
  /// - 답글: pComment = 부모 댓글의 ID
  ///
  /// 사용 예시:
  /// // 주 댓글 작성
  /// await addComment(
  ///   postId: "post123",
  ///   userId: "user456",
  ///   nickName: "홍길동",
  ///   content: "좋은 글이네요!",
  ///   pComment: null,  ← 주 댓글
  /// );
  ///
  /// // 답글 작성
  /// await addComment(
  ///   postId: "post123",
  ///   userId: "user789",
  ///   nickName: "김철수",
  ///   content: "@홍길동 저도 동감합니다",
  ///   pComment: "comment_abc",  ← 답글 (부모 댓글 ID)
  /// );
  ///
  /// 알림 연동 시 참고사항: ⚠️
  /// - pComment가 null이면: 게시글 작성자에게 알림
  /// - pComment가 있으면: 부모 댓글 작성자에게 알림
  /// - userId를 사용해 알림 대상자 조회 가능
  /// ========================================


  /// 添加评论（支持主评论和回复）
  /// 参数:
  /// - postId: 帖子 ID
  /// - userId: 用户 ID
  /// - nickName: 用户昵称
  /// - content: 评论内容
  /// - pComment: 父评论 ID（如果是回复则传入，主评论则为 null）
  /// 返回: bool - true=成功, false=失败
  Future<bool> addComment({
    required String postId,
    required String userId,
    required String nickName,
    required String content,
    String? pComment, // 父评论 ID（回复时使用）
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
        'pComment': pComment, // 如果是回复，存储父评论 ID
      };

      // 添加评论到 comment 子集合
      await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .add(commentData);

      // 增加帖子的评论计数
      await _firestore.collection('post').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('댓글 추가 실패: $e');
      return false;
    }
  }


  /// ========================================
  /// deleteComment - 댓글 삭제
  /// ========================================
  ///
  /// 파라미터:
  /// - postId: 게시글 ID
  /// - commentId: 삭제할 댓글 ID
  ///
  /// 리턴:
  /// - bool: 성공 시 true, 실패 시 false
  ///
  /// 동작 방식:
  /// 1. comment 서브컬렉션에서 해당 문서 삭제
  /// 2. post의 commentCount 필드를 -1 감소
  ///
  /// ⚠️ 주의사항:
  /// - 현재는 단일 댓글만 삭제함
  /// - 주 댓글을 삭제해도 하위 답글은 자동 삭제되지 않음
  /// - 하위 답글을 함께 삭제하려면 추가 로직 필요:
  ///   1. pComment == commentId인 모든 답글 조회
  ///   2. 재귀적으로 하위 답글 모두 삭제
  ///   3. commentCount를 (삭제된 댓글 수)만큼 감소
  ///
  /// 개선 방안 (향후 적용 가능):
  /// Future<bool> deleteCommentWithReplies(String postId, String commentId) async {
  ///   // 1. 모든 하위 답글 찾기
  ///   final allReplies = await _getAllReplies(commentId);
  ///   // 2. 배치 삭제
  ///   WriteBatch batch = _firestore.batch();
  ///   // 3. 주 댓글 + 답글 모두 삭제
  ///   // 4. commentCount -= (1 + allReplies.length)
  /// }
  /// ========================================
  /// 删除评论
  /// 参数:
  /// - postId: 帖子 ID
  /// - commentId: 评论 ID
  /// 返回: bool - true=成功, false=失败

  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      // 删除评论文档
      await _firestore
          .collection('post')
          .doc(postId)
          .collection('comment')
          .doc(commentId)
          .delete();

      // 减少帖子的评论计数
      await _firestore.collection('post').doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('댓글 삭제 실패: $e');
      return false;
    }
  }
}