// community/widgets/community_detail/comment_list_v2.dart

import 'package:flutter/material.dart';
import '../../models/comment_model.dart';
import 'comment_item.dart';

/// 评论列表组件 V2（支持展开/收起）
class CommentsList extends StatelessWidget {
  final bool isLoading;
  final List<Comment> comments;
  final String? highlightCommentId;
  final Map<String, GlobalKey> commentKeys;
  final Set<String> expandedCommentIds;
  final Function(Comment) onReplyToComment;
  final Function(String) onToggleExpanded;
  final List<Comment> Function(String) getAllReplies;
  final String? postAuthorId; // ✅ 新增

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
    this.postAuthorId, // ✅ 新增
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (comments.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('아직 댓글이 없습니다', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

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
            postAuthorId: postAuthorId, // ✅ 添加这一行
          );
        },
      ),
    );
  }
}