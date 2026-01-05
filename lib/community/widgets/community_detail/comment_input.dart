// community/widgets/community_detail/comment_input.dart

import 'package:flutter/material.dart';
import '../../models/comment_model.dart';
import '../../../common/app_colors.dart';

/// 评论输入框组件
class CommentInput extends StatelessWidget {
  final bool isExpanded;
  final Comment? replyingTo;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onExpand;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const CommentInput({
    Key? key,
    required this.isExpanded,
    this.replyingTo,
    required this.controller,
    required this.focusNode,
    required this.onExpand,
    required this.onCancel,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: isExpanded
          ? ExpandedCommentInput(
        replyingTo: replyingTo,
        controller: controller,
        focusNode: focusNode,
        onCancel: onCancel,
        onSubmit: onSubmit,
      )
          : CollapsedCommentInput(onExpand: onExpand),
    );
  }
}

/// 折叠状态的输入框
class CollapsedCommentInput extends StatelessWidget {
  final VoidCallback onExpand;

  const CollapsedCommentInput({
    Key? key,
    required this.onExpand,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onExpand,
      child: Row(
        children: [
          Icon(Icons.comment),
          SizedBox(width: 8),
          Text('댓글을 작성하세요...'),
        ],
      ),
    );
  }
}

/// 展开状态的输入框
class ExpandedCommentInput extends StatelessWidget {
  final Comment? replyingTo;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const ExpandedCommentInput({
    Key? key,
    this.replyingTo,
    required this.controller,
    required this.focusNode,
    required this.onCancel,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (replyingTo != null)
          ReplyingToHeader(
            replyingTo: replyingTo!,
            onCancel: onCancel,
          ),
        CommentInputField(
          controller: controller,
          focusNode: focusNode,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}

/// 回复目标头部
class ReplyingToHeader extends StatelessWidget {
  final Comment replyingTo;
  final VoidCallback onCancel;

  const ReplyingToHeader({
    Key? key,
    required this.replyingTo,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('${replyingTo.nickName}님에게 답글'),
        Spacer(),
        IconButton(
          icon: Icon(Icons.close),
          onPressed: onCancel,
        ),
      ],
    );
  }
}

/// 评论输入文本框
class CommentInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  const CommentInputField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: '댓글을 입력하세요...',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.send, color: AppColors.primaryColor),
          onPressed: onSubmit,
        ),
      ],
    );
  }
}