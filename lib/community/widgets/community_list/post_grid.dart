// community/widgets/community_list/post_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/post_model.dart';
import '../../../common/app_colors.dart';

/// 帖子瀑布流网格组件（高度仿小红书）
class PostGrid extends StatelessWidget {
  final bool isLoading;
  final List<Post> posts;
  final Function(Post) onPostTap;

  const PostGrid({
    Key? key,
    required this.isLoading,
    required this.posts,
    required this.onPostTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (posts.isEmpty) {
      return const Expanded(
        child: Center(child: Text('게시글이 없습니다')),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: MasonryGridView.count(
          crossAxisCount: 2,
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

/// 单个帖子卡片（高度仿小红书）
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const PostCard({
    Key? key,
    required this.post,
    required this.onTap,
  }) : super(key: key);

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
            _buildCover(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.nickName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.bookmark_border, size: 12, color: Colors.grey[500]),
                      SizedBox(width: 2),
                      Text(
                        '${post.bookmarkCount}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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

  /// 构建封面
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

  /// ✅ 文字封面（带网格背景，小红书风格）
  Widget _buildTextCover() {
    final displayText = post.title.length > 80
        ? '${post.title.substring(0, 80)}...'
        : post.title;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        constraints: BoxConstraints(
          minHeight: 160,
          maxHeight: 240,
        ),
        child: Stack(
          children: [
            // ✅ 网格背景
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(
                  gridColor: Color(0xFFCEDEF2),
                  gridSize: 20.0,
                ),
              ),
            ),
            // ✅ 白色渐变遮罩（让网格不会太抢眼）
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.50),
                      Colors.white.withOpacity(0.60),
                    ],
                  ),
                ),
              ),
            ),
            // ✅ 文字内容（自适应大小）
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 根据容器高度自适应字体大小
                  final containerHeight = constraints.maxHeight;
                  final fontSize = (containerHeight / 8).clamp(16.0, 28.0);

                  return Align(
                    alignment: Alignment.center,
                    child: Text(
                      displayText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF4A5568),
                        fontSize: fontSize,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ 网格背景绘制器
class GridPainter extends CustomPainter {
  final Color gridColor;
  final double gridSize;

  GridPainter({
    required this.gridColor,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 2.0  // ✅ 加粗网格线
      ..style = PaintingStyle.stroke;

    // 绘制垂直线
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 绘制水平线
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.gridColor != gridColor ||
        oldDelegate.gridSize != gridSize;
  }
}