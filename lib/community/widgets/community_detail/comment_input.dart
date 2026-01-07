// ==================================================================================
// 1. comment_input.dart - 댓글 입력창 컴포넌트
// ==================================================================================
// community/widgets/community_detail/comment_input.dart

import 'package:flutter/material.dart';
import '../../models/comment_model.dart';
import '../../../common/app_colors.dart';

/// 댓글 입력창 메인 컴포넌트
class CommentInput extends StatelessWidget {
  final bool isExpanded; // 입력창 확장 여부
  final Comment? replyingTo; // 답글 대상 댓글
  final TextEditingController controller; // 텍스트 입력 컨트롤러
  final FocusNode focusNode; // 포커스 노드
  final VoidCallback onExpand; // 확장 콜백
  final VoidCallback onCancel; // 취소 콜백
  final VoidCallback onSubmit; // 제출 콜백

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

/// 축소된 상태의 입력창
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
          SizedBox(width: 8),
          Text('댓글을 작성하세요...'),
        ],
      ),
    );
  }
}

/// 확장된 상태의 입력창
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

/// 답글 대상 헤더
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
        Text('${replyingTo.nickName}님에게 답글', style: TextStyle(fontSize: 15)),
        Spacer(),
      ],
    );
  }
}

/// 댓글 입력 텍스트 필드
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
      ],
    );
  }
}