// comment_item_v2.dart - 完整修改版

import 'package:flutter/material.dart';
import '../../models/comment_model.dart';
import '../../../common/app_colors.dart';

/// 单个评论项组件 V2（支持展开/收起）
class CommentItem extends StatelessWidget {
  final Comment mainComment;
  final List<Comment> replies;
  final bool isExpanded;
  final String? highlightCommentId;
  final Map<String, GlobalKey> commentKeys;
  final Function(Comment) onReplyToComment;
  final VoidCallback onToggleExpanded;
  final String? postAuthorId; // ✅ 新增：帖子作者ID

  const CommentItem({
    Key? key,
    required this.mainComment,
    required this.replies,
    required this.isExpanded,
    this.highlightCommentId,
    required this.commentKeys,
    required this.onReplyToComment,
    required this.onToggleExpanded,
    this.postAuthorId, // ✅ 新增
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMainHighlighted = highlightCommentId == mainComment.id;
    final hasReplies = replies.isNotEmpty;

    return Column(
      key: commentKeys[mainComment.id],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主评论
        MainCommentTile(
          comment: mainComment,
          isHighlighted: isMainHighlighted,
          onTap: () => onReplyToComment(mainComment),
          postAuthorId: postAuthorId, // ✅ 传递
        ),

        // 回复区域
        if (hasReplies)
          RepliesSection(
            replies: replies,
            isExpanded: isExpanded,
            highlightCommentId: highlightCommentId,
            commentKeys: commentKeys,
            onReplyToComment: onReplyToComment,
            onToggleExpanded: onToggleExpanded,
            postAuthorId: postAuthorId, // ✅ 传递
          ),

        Divider(height: 1, thickness: 1, color: Colors.grey[100]),
      ],
    );
  }
}

/// 主评论 Tile
class MainCommentTile extends StatelessWidget {
  final Comment comment;
  final bool isHighlighted;
  final VoidCallback onTap;
  final String? postAuthorId; // ✅ 新增

  const MainCommentTile({
    Key? key,
    required this.comment,
    required this.isHighlighted,
    required this.onTap,
    this.postAuthorId, // ✅ 新增
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAuthor = postAuthorId != null && postAuthorId == comment.userId;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.secondaryColor.withOpacity(0.1): Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 昵称 + 作者标签
              Row(
                children: [
                  Text(
                    comment.nickName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  if (isAuthor) ...[
                    SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '작성자',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 4),
              Text(
                comment.content,
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              SizedBox(height: 4),
              Text(
                comment.cdate.toString().split(' ')[0],
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 回复区域（支持折叠）
class RepliesSection extends StatelessWidget {
  final List<Comment> replies;
  final bool isExpanded;
  final String? highlightCommentId;
  final Map<String, GlobalKey> commentKeys;
  final Function(Comment) onReplyToComment;
  final VoidCallback onToggleExpanded;
  final String? postAuthorId; // ✅ 新增

  const RepliesSection({
    Key? key,
    required this.replies,
    required this.isExpanded,
    this.highlightCommentId,
    required this.commentKeys,
    required this.onReplyToComment,
    required this.onToggleExpanded,
    this.postAuthorId, // ✅ 新增
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayedReplies = isExpanded ? replies : [replies.first];
    final hasMore = replies.length > 1;

    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 显示的回复
          ...displayedReplies.map((reply) {
            final isReplyHighlighted = highlightCommentId == reply.id;
            return ReplyTile(
              key: commentKeys[reply.id],
              reply: reply,
              isHighlighted: isReplyHighlighted,
              onTap: () => onReplyToComment(reply),
              postAuthorId: postAuthorId, // ✅ 传递
            );
          }).toList(),

          // 展开/收起按钮
          if (hasMore)
            InkWell(
              onTap: onToggleExpanded,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    SizedBox(width: 4),
                    Text(
                      isExpanded
                          ? '접기'
                          : '${replies.length - 1}개의 답글 더보기',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 单个回复 Tile
class ReplyTile extends StatelessWidget {
  final Comment reply;
  final bool isHighlighted;
  final VoidCallback onTap;
  final String? postAuthorId; // ✅ 新增

  const ReplyTile({
    Key? key,
    required this.reply,
    required this.isHighlighted,
    required this.onTap,
    this.postAuthorId, // ✅ 新增
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAuthor = postAuthorId != null && postAuthorId == reply.userId;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.secondaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 昵称 + 作者标签
            Row(
              children: [
                Text(
                  reply.nickName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primaryColor.withOpacity(0.6),
                  ),
                ),
                if (isAuthor) ...[
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '작성자',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 2),
            Text(
              reply.content,
              style: TextStyle(fontSize: 14, height: 1.3, color: Colors.black.withOpacity(0.7)),
            ),
            SizedBox(height: 2),
            Text(
              reply.cdate.toString().split(' ')[0],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}