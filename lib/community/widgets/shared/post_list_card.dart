// community/widgets/shared/post_list_card.dart

import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../../common/app_colors.dart';
import '../../../common/bookmark_button.dart';

/// 帖子列表卡片类型
enum PostCardActionType {
  bookmark,    // 书签按钮
  myPost,      // 我的帖子（可能需要编辑/删除按钮）
  none,        // 无操作按钮
}

/// 通用帖子列表卡片组件
class PostListCard extends StatelessWidget {
  final Post post;
  final PostCardActionType actionType;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;

  // 书签模式相关
  final String? currentUserId;
  final Future<void> Function()? onBookmarkRemove;

  // 我的帖子模式相关
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostListCard({
    Key? key,
    required this.post,
    required this.actionType,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    this.currentUserId,
    this.onBookmarkRemove,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(color: AppColors.primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ✅ 只有当有图片时才显示缩略图
            if (post.thumbnailUrl.isNotEmpty) _buildThumbnail(),

            // 右侧信息区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部：分类标签 + > 图标
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCategoryTag(),
                      if (!isSelectionMode)
                        Icon(
                          Icons.chevron_right,
                          size: 22,
                          color: Colors.grey[400],
                        ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // 标题
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),

                  // 作者昵称
                  Text(
                    post.nickName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),

                  // 底部信息栏
                  _buildMetaInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 缩略图
  Widget _buildThumbnail() {
    return Padding(
      padding: EdgeInsets.only(right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          post.thumbnailUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 100,
              height: 100,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// 分类标签
  Widget _buildCategoryTag() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        post.category,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 底部元信息
  Widget _buildMetaInfo() {
    return Row(
      children: [
        Text(
          '댓글 ${post.commentCount}',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        SizedBox(width: 8),
        Text(
          '북마크 ${post.bookmarkCount}',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Spacer(),

        // 根据不同类型显示不同的操作按钮
        _buildActionButtons(),
      ],
    );
  }

  /// 构建操作按钮区域
  Widget _buildActionButtons() {
    // 选择模式：显示复选框
    if (isSelectionMode) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey,
            width: 2,
          ),
        ),
        child: isSelected
            ? Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      );
    }

    // 非选择模式：根据类型显示不同按钮
    switch (actionType) {
      case PostCardActionType.bookmark:
        return _buildBookmarkButton();

      case PostCardActionType.myPost:
        return _buildMyPostActions();

      case PostCardActionType.none:
      default:
        return SizedBox.shrink();
    }
  }

  /// 书签按钮
  Widget _buildBookmarkButton() {
    if (currentUserId == null) return SizedBox.shrink();

    return BookmarkButton(
      isInitialBookmarked: true,
      size: 20,
      isTransparent: true,
      onToggle: (isBookmarked) async {
        if (!isBookmarked && onBookmarkRemove != null) {
          await onBookmarkRemove!();
        }
      },
    );
  }

  /// 我的帖子操作按钮（编辑/删除）- 更紧凑
  Widget _buildMyPostActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 编辑按钮
        if (onEdit != null)
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
          ),

        SizedBox(width: 4),

        // 删除按钮
        if (onDelete != null)
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}