// community/widgets/community_detail/content_section.dart

import 'package:flutter/material.dart';
import '../../models/post_model.dart';

/// 帖子内容区域组件（高度仿小红书）
class PostContentSection extends StatelessWidget {
  final Post post;
  final Widget commentsWidget;

  const PostContentSection({
    Key? key,
    required this.post,
    required this.commentsWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height - 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片
          PostThumbnail(post: post),

          // 分类标签（在标题上方）
          PostCategoryTag(post: post),
          SizedBox(height: 8),

          // 标题
          PostTitle(post: post),
          SizedBox(height: 8),

          // 作者信息（只显示昵称，放在标题下方）
          PostAuthorInfo(post: post),
          SizedBox(height: 18),

          // 正文
          PostContentText(post: post),
          SizedBox(height: 16),

          // 日期 + Bookmark 数
          PostMetaInfo(post: post),
          SizedBox(height: 16),

          // 分割线
          Divider(height: 1, thickness: 6, color: Colors.grey[100]),

          // 评论标题
          PostCommentHeader(commentCount: post.commentCount),

          // 评论列表
          commentsWidget,
        ],
      ),
    );
  }
}

/// 分类标签（单独放在标题上方）
class PostCategoryTag extends StatelessWidget {
  final Post post;

  const PostCategoryTag({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          post.category,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 帖子标题（简洁）
class PostTitle extends StatelessWidget {
  final Post post;

  const PostTitle({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        post.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          height: 1.4,
          color: Colors.black,
        ),
      ),
    );
  }
}

/// ✅ 帖子缩略图（限制最大高度为屏幕的2/3）
class PostThumbnail extends StatelessWidget {
  final Post post;

  const PostThumbnail({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (post.thumbnailUrl.isEmpty) {
      return SizedBox.shrink();
    }

    // ✅ 获取屏幕高度的 2/3
    final maxHeight = MediaQuery.of(context).size.height * 0.67;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight,  // ✅ 限制最大高度
      ),
      child: Image.network(
        post.thumbnailUrl,
        width: double.infinity,
        fit: BoxFit.cover,  // ✅ 填满宽度，超出部分裁剪
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 300,
            color: Colors.grey[200],
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return SizedBox.shrink();
        },
      ),
    );
  }
}

/// 作者信息（只显示昵称，放在标题下方）
class PostAuthorInfo extends StatelessWidget {
  final Post post;

  const PostAuthorInfo({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        post.nickName,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

/// 帖子正文
class PostContentText extends StatelessWidget {
  final Post post;

  const PostContentText({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        post.content,
        style: TextStyle(
          fontSize: 15,
          color: Colors.black87,
          height: 1.6,
        ),
      ),
    );
  }
}

/// 元信息（日期 + Bookmark 数）
class PostMetaInfo extends StatelessWidget {
  final Post post;

  const PostMetaInfo({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 日期
          Text(
            post.cdate.toString().split(' ')[0],
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),

          SizedBox(width: 12),

          // Bookmark 数
          Icon(Icons.bookmark_border, size: 13, color: Colors.grey[500]),
          SizedBox(width: 3),
          Text(
            '${post.bookmarkCount}',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// 评论标题 + 评论数
class PostCommentHeader extends StatelessWidget {
  final int commentCount;

  const PostCommentHeader({Key? key, required this.commentCount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: Row(
        children: [
          Text(
            '댓글',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 6),
          Text(
            '$commentCount',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}