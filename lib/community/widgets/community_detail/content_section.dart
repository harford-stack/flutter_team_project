// ==================================================================================
// 4. content_section.dart - 게시글 내용 영역 컴포넌트
// ==================================================================================
// community/widgets/community_detail/content_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_team_project/common/app_colors.dart';
import '../../models/post_model.dart';

/// 게시글 내용 영역 컴포넌트
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
          // 썸네일 이미지
          PostThumbnail(post: post),

          // 카테고리 태그
          PostCategoryTag(post: post),
          SizedBox(height: 8),

          // 제목
          PostTitle(post: post),
          SizedBox(height: 8),

          // 작성자 정보
          PostAuthorInfo(post: post),
          SizedBox(height: 18),

          // 본문
          PostContentText(post: post),
          SizedBox(height: 16),

          // 메타 정보 (날짜 + 북마크 수)
          PostMetaInfo(post: post),
          SizedBox(height: 16),

          // 구분선
          Divider(height: 1, thickness: 6, color: Colors.grey[100]),

          // 댓글 헤더
          PostCommentHeader(commentCount: post.commentCount),

          // 댓글 목록
          commentsWidget,
        ],
      ),
    );
  }
}

/// 카테고리 태그
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
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          post.category,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 게시글 제목
class PostTitle extends StatelessWidget {
  final Post post;

  const PostTitle({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 세로 강조선
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 12),
            // 제목 텍스트
            Expanded(
              child: Text(
                post.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  height: 1.4,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 썸네일 이미지
class PostThumbnail extends StatelessWidget {
  final Post post;

  const PostThumbnail({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (post.thumbnailUrl.isEmpty) {
      return SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: Container(
        width: screenWidth,
        height: screenWidth,
        child: Image.network(
          post.thumbnailUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// 전체 이미지 보기 (확대/축소 지원)
  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // 이미지 (확대/축소 지원)
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  post.thumbnailUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // 닫기 버튼
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 작성자 정보
class PostAuthorInfo extends StatelessWidget {
  final Post post;

  const PostAuthorInfo({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Text(
            post.nickName,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 6),
          Icon(
            Icons.person,
            size: 18,
            color: Colors.black.withOpacity(0.6),
          ),
        ],
      ),
    );
  }
}

/// 게시글 본문
class PostContentText extends StatelessWidget {
  final Post post;

  const PostContentText({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25),
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

/// 메타 정보 (날짜 + 북마크 수)
class PostMetaInfo extends StatelessWidget {
  final Post post;

  const PostMetaInfo({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 날짜
          Text(
            post.cdate.toString().split(' ')[0],
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),

          SizedBox(width: 12),

          // 북마크 수
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

/// 댓글 헤더 (제목 + 댓글 수)
class PostCommentHeader extends StatelessWidget {
  final int commentCount;

  const PostCommentHeader({Key? key, required this.commentCount})
      : super(key: key);

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
              color: Colors.black.withOpacity(0.4),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 6),
          Text(
            '$commentCount',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}