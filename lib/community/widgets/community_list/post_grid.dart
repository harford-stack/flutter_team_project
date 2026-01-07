// ==================================================================================
// 5. post_grid.dart - 게시글 메이슨리 레이아웃 (커뮤니티 메인용)
// ==================================================================================
// community/widgets/community_list/post_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/post_model.dart';
import '../../../common/app_colors.dart';

/// 게시글 그리드 (메이슨리 레이아웃)
class PostGrid extends StatelessWidget {
  /// =====================================================================================
  /// 필드
  /// =====================================================================================
  final bool isLoading; // 로딩 상태
  final List<Post> posts; // 게시글 목록
  final Function(Post) onPostTap; // 게시글 클릭 콜백

  /// =====================================================================================
  /// 생성자
  /// =====================================================================================
  const PostGrid({
    Key? key,
    required this.isLoading,
    required this.posts,
    required this.onPostTap,
  }) : super(key: key);

  /// =====================================================================================
  /// UI 구현
  /// =====================================================================================
  @override
  Widget build(BuildContext context) {
    // 로딩 중
    if (isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 게시글이 없는 경우
    if (posts.isEmpty) {
      return const Expanded(
        child: Center(child: Text('게시글이 없습니다')),
      );
    }

    // 메이슨리 레이아웃 (핀터레스트 스타일)
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: MasonryGridView.count(
          crossAxisCount: 2, // 2열 그리드
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return PostCard(
              post: post,
              onTap: () => onPostTap(post),
            );
          },
        ),
      ),
    );
  }
}

/// 개별 게시글 카드
class PostCard extends StatelessWidget {
  /// =====================================================================================
  /// 필드
  /// =====================================================================================
  final Post post;
  final VoidCallback onTap;

  const PostCard({
    Key? key,
    required this.post,
    required this.onTap,
  }) : super(key: key);

  /// =====================================================================================
  /// UI 구현
  /// =====================================================================================
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 커버 이미지
            _buildCover(),

            // 내용
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // 닉네임 + 북마크 수
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.nickName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.bookmark_border, size: 13, color: Colors.grey[500]),
                      SizedBox(width: 2),
                      Text(
                        '${post.bookmarkCount}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =====================================================================================
  /// 위젯들
  /// =====================================================================================
  /// 커버 이미지 (썸네일 있으면 표시, 없으면 카테고리별 배경)
  Widget _buildCover() {
    if (post.thumbnailUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        child: Image.network(
          post.thumbnailUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildTextCover();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 180,
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      );
    }

    return _buildTextCover();
  }

  /// 텍스트 커버 (카테고리별 배경 이미지)
  /// 중요: 썸네일이 없을 때 카테고리에 따라 다른 배경 표시
  Widget _buildTextCover() {
    final bgImage = _getBackgroundByCategory(post.category);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// 카테고리별 배경 이미지 가져오기
  /// 중요: assets 폴더에 해당 이미지 파일이 있어야 함
  String _getBackgroundByCategory(String category) {
    switch (category) {
      case '자유게시판':
        return 'assets/post_bg/bg_free.png';

      case '문의사항':
        return 'assets/post_bg/bg_inquiry.png';

      default:
        return 'assets/post_bg/bg_default.png';
    }
  }
}