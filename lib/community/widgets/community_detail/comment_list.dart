// ==================================================================================
// 3. comment_list.dart - 댓글 목록 컴포넌트
// ==================================================================================
// community/widgets/community_detail/comment_list.dart

import 'package:flutter/material.dart';
import '../../models/comment_model.dart';
import 'comment_item.dart';

/// 댓글 목록 컴포넌트 (확장/축소 지원)
class CommentsList extends StatelessWidget {
  final bool isLoading; // 로딩 중 여부
  final List<Comment> comments; // 전체 댓글 목록
  final String? highlightCommentId; // 하이라이트할 댓글 ID
  final Map<String, GlobalKey> commentKeys; // 댓글 키 맵
  final Set<String> expandedCommentIds; // 확장된 댓글 ID 세트
  final Function(Comment) onReplyToComment; // 답글 콜백
  final Function(String) onToggleExpanded; // 확장 토글 콜백
  final List<Comment> Function(String) getAllReplies; // 답글 가져오기 함수
  final String? postAuthorId; // 게시글 작성자 ID

  const CommentsList({
    Key? key,
    required this.isLoading,
    required this.comments,
    this.highlightCommentId,
    required this.commentKeys,
    required this.expandedCommentIds,
    required this.onReplyToComment,
    required this.onToggleExpanded,
    required this.getAllReplies,
    this.postAuthorId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 로딩 중일 때
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // 댓글이 없을 때
    if (comments.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('아직 댓글이 없습니다', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // 주 댓글만 필터링
    final mainComments = comments.where((c) => c.pComment == null).toList();

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 10),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: mainComments.length,
        itemBuilder: (context, index) {
          final mainComment = mainComments[index];
          final replies = getAllReplies(mainComment.id);
          final isExpanded = expandedCommentIds.contains(mainComment.id);

          return CommentItem(
            mainComment: mainComment,
            replies: replies,
            isExpanded: isExpanded,
            highlightCommentId: highlightCommentId,
            commentKeys: commentKeys,
            onReplyToComment: onReplyToComment,
            onToggleExpanded: () => onToggleExpanded(mainComment.id),
            postAuthorId: postAuthorId,
          );
        },
      ),
    );
  }
}