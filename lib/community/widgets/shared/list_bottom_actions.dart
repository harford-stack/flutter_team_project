// community/widgets/shared/list_bottom_actions.dart

import 'package:flutter/material.dart';
import '../../../common/app_colors.dart';

/// 底部操作栏类型
enum ListActionType {
  bookmark,  // 书签解除
  deletePost, // 帖子删除
}

/// 通用底部操作栏组件
///
/// 使用场景：
/// - bookmark_list_screen.dart (书签管理)
/// - my_post_list_screen.dart (我的帖子管理)
class ListBottomActions extends StatelessWidget {
  final ListActionType actionType;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  const ListBottomActions({
    Key? key,
    required this.actionType,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
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
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧按钮：主要操作
          Expanded(
            child: ElevatedButton(
              // ✅ 修复：按钮始终可点击
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                // ✅ 修复：根据状态动态改变背景色
                backgroundColor: _getButtonColor(),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _getPrimaryButtonText(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),

          // 右侧按钮：取消/返回
          Expanded(
            child: OutlinedButton(
              onPressed: onSecondaryAction,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isSelectionMode ? '취소' : '돌아가기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ 新增：动态获取按钮背景色
  Color _getButtonColor() {
    // 选择模式 + 已选择项 → 红色（危险操作）
    if (isSelectionMode && selectedCount > 0) {
      return Colors.red;
    }
    // 其他情况 → 主题色
    return AppColors.primaryColor;
  }

  /// 获取主按钮文本
  String _getPrimaryButtonText() {
    if (isSelectionMode) {
      if (selectedCount == 0) {
        return actionType == ListActionType.bookmark
            ? '삭제할 항목 선택'
            : '삭제할 게시글 선택';
      } else {
        return actionType == ListActionType.bookmark
            ? '북마크 해제 ($selectedCount)'
            : '게시글 삭제 ($selectedCount)';
      }
    } else {
      return actionType == ListActionType.bookmark
          ? '북마크 해제'
          : '게시글 삭제';
    }
  }
}