// ==================================================================================
// 2. post_list_card.dart - 게시글 리스트 카드 (공유 컴포넌트)
// ==================================================================================
// community/widgets/shared/post_list_card.dart

import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../../common/app_colors.dart';
import '../../../common/bookmark_button.dart';

/// 게시글 리스트 카드 타입
enum PostCardActionType {
  bookmark, // 북마크 버튼
  myPost, // 내 게시글 (수정/삭제 버튼)
  none, // 액션 없음
}

/// 통합 게시글 리스트 카드 컴포넌트
/// 사용처: 북마크 목록, 내 게시글 목록
class PostListCard extends StatelessWidget {
  /// =====================================================================================
  /// 필드
  /// =====================================================================================
  /// 1. 기본 정보
  final Post post; // 게시글 데이터
  final PostCardActionType actionType; // 카드 타입
  final bool isSelected; // 선택 여부
  final bool isSelectionMode; // 선택 모드 여부
  final VoidCallback onTap; // 카드 클릭 콜백

  /// 2. 북마크 모드 관련
  final String? currentUserId; // 현재 사용자 ID
  final Future<void> Function()? onBookmarkRemove; // 북마크 해제 콜백

  /// 3. 내 게시글 모드 관련
  final VoidCallback? onEdit; // 수정 콜백
  final VoidCallback? onDelete; // 삭제 콜백

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

  /// =====================================================================================
  /// UI 구현
  /// =====================================================================================
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
          // 선택된 경우 테두리 표시
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 카테고리 태그 + 화살표 아이콘
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryTag(),
                // 선택 모드가 아닐 때만 화살표 표시
                if (!isSelectionMode)
                  Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: Colors.grey[400],
                  ),
              ],
            ),
            SizedBox(height: 12),

            // 중간: 썸네일 + 제목과 닉네임
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.thumbnailUrl.isNotEmpty) _buildThumbnail(),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: post.thumbnailUrl.isNotEmpty ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        post.nickName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // 하단: 메타 정보
            _buildMetaInfo(),
          ],
        ),
      ),
    );
  }

  /// =====================================================================================
  /// 위젯들
  /// =====================================================================================
  /// 썸네일 이미지
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

  /// 카테고리 태그
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

  /// 하단 메타 정보
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

        // 타입에 따른 액션 버튼
        _buildActionButtons(),
      ],
    );
  }

  /// 액션 버튼 영역
  /// 중요: 선택 모드일 때는 체크박스, 아닐 때는 타입별 액션 버튼
  Widget _buildActionButtons() {
    // 선택 모드: 체크박스 표시
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
        child: isSelected ? Icon(Icons.check, size: 16, color: Colors.white) : null,
      );
    }

    // 일반 모드: 타입별 버튼
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

  /// 북마크 버튼
  Widget _buildBookmarkButton() {
    if (currentUserId == null) return SizedBox.shrink();

    return BookmarkButton(
      isInitialBookmarked: true,
      size: 30,
      isTransparent: true,
      onToggle: (isBookmarked) async {
        if (!isBookmarked && onBookmarkRemove != null) {
          await onBookmarkRemove!();
        }
      },
    );
  }

  /// 내 게시글 액션 버튼 (수정/삭제)
  Widget _buildMyPostActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 수정 버튼
        if (onEdit != null)
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.edit_outlined,
                size: 23,
                color: AppColors.primaryColor,
              ),
            ),
          ),

        SizedBox(width: 4),

        // 삭제 버튼
        if (onDelete != null)
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline,
                size: 23,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}